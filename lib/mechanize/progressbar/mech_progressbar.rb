module MechanizeProgressBarAPI
  ### Usage:
  ###   require 'mechanize'
  ###   require 'mechanize/progressbar'
  ###   agent = Mechanize.new
  ###   agent.progressbar{ agent.get(large_file) }
  ###   agent.get(some_page)
  ###   agent.progressbar{ agent.page.link_with(:text => 'download here').click }
  ###
  ### If you want to set parameters to ProgressBar object,
  ###   agent.progressbar(:title => 'large_file', :format_arguments => @fmt) do
  ###     agent.get(large_file)
  ###   end
  ### ProgressBar is gem lib. Please install with 'gem install progressbar'.
  ###
  ### options:
  ### [:single] enables single line mode, original ProgressBar gem behavior. default is false
  ### [:title] ProgressBar.new(*title*, total, out), default is empty
  ### [:total] ProgressBar.new(title, *total*, out), default is 'Content-Length' response header
  ### [:out] ProgressBar.new(title, total, *out*), default is $stderr
  ### [:format] ProgressBar.new(*args).format=*format*, default is nil
  ### [:format_arguments]  ProgressBar.new(*args).format_arguments=*format_arguments*, default is nil
  ### [:reversed] ReversedProgressBar.new(*args), default is false
  ### [:file_transfer_mode] enables ProgressBar#file_transfer_mode, default is true
  ### [:suppress_logger] makes Logger's output and Progressbar's output independent
  def progressbar(agent_or_pbar_opts = self, pbar_opts = {})
    if agent_or_pbar_opts.kind_of?(Hash) then
      agent, pbar_opts = self, agent_or_pbar_opts
    else
      agent = agent_or_pbar_opts
    end
    MechanizeProgressBar.register(agent, pbar_opts)
    if block_given?
      begin
        yield agent
      rescue Exception, Mechanize::ResponseCodeError
        MechanizeProgressBar.unregister(agent)
        raise
      end
      MechanizeProgressBar.unregister(agent)
    else
      MechanizeProgressBar.reserve_pseudo_unregisteration(agent)
    end
    agent
  end
end

module MechanizeProgressBar
  def self.pbar_hooks ; @pbar_hooks ||= []; end
  def self.default_out ; @default_out ||= $stderr; end
  def self.default_out=(out); @default_out = out; end

  def self.build(chain_params)
    pbar_opts = chain_params[:progressbar]

    out = pbar_opts[:out] || pbar_opts[:output] || self.default_out
    if pbar_opts[:single] then
      title = pbar_opts[:title] || chain_params[:uri].host
      format = pbar_opts[:format]
      format_arguments = pbar_opts[:format_arguments]
    else
      title = pbar_opts[:title] || ""
      format = pbar_opts[:format] || "%3d%% %s %s"
      format_arguments = pbar_opts[:format_arguments] || [:percentage, :bar, :stat_for_file_transfer]
      out.print "#{pbar_opts[:title]||chain_params[:uri]}\n"
    end
    total = pbar_opts[:total] || filesize(chain_params)
    pbar_class = pbar_opts[:reversed] ? ReversedProgressBar : ProgressBar

    progressbar = pbar_class.new(title, total, out)
    progressbar.file_transfer_mode unless pbar_opts[:file_transfer_mode]
    progressbar.format = format if format
    progressbar.format_arguments = format_arguments if format_arguments
    return progressbar
  end

  def self.filesize(chain_params)
    content_length = chain_params[:response]['content-length']
    content_length ? content_length.to_i : 0
  end

  def self.register(agent, pbar_opts)
    pre_hook = lambda{|options| options[:progressbar] = pbar_opts}
    self.pbar_hooks << pre_hook
    agent.pre_connect_hooks << pre_hook
  end

  def self.unregister(agent)
    agent.pre_connect_hooks.each do |pr|
      agent.pre_connect_hooks.delete_if{ self.pbar_hooks.delete(pr)}
    end
  end

  def self.reserve_pseudo_unregisteration(agent)
    agent.post_connect_hooks << lambda{|options|
      MechanizeProgressBar.unregister(agent) if options[:agent] && options[:progressbar]
    }
  end

  def self.http_ok?(params)
    params[:progressbar] && params[:response].code == '200'
  end

  def self.suppress_logger?(params)
    params[:progressbar] && params[:progressbar][:suppress_logger]
  end
end



class Mechanize   # has 6 added/modified lines
  include MechanizeProgressBarAPI # (1of6)a
  class Chain
    class ResponseReader
      def handle(ctx, params)
        params[:response] = @response
        body = StringIO.new
        total = 0
        pbar = MechanizeProgressBar.build(params) if MechanizeProgressBar.http_ok?(params) # (2of6)a
        @response.read_body { |part|
          total += part.length
          body.write(part)
#         Mechanize.log.debug("Read #{total} bytes") if Mechanize.log
          Mechanize.log.debug("Read #{total} bytes") if Mechanize.log && !MechanizeProgressBar.suppress_logger?(params) # (3of6)m
          pbar.inc(part.length) if MechanizeProgressBar.http_ok?(params) # (4of6)a
        }
        body.rewind
        pbar.finish if MechanizeProgressBar.http_ok?(params) # (5of6)a
        Mechanize.log.debug("Read #{total} bytes") if Mechanize.log && MechanizeProgressBar.suppress_logger?(params) # (6of6)a

        res_klass = Net::HTTPResponse::CODE_TO_OBJ[@response.code.to_s]
        raise ResponseCodeError.new(@response) unless res_klass

        # Net::HTTP ignores EOFError if Content-length is given, so we emulate it here.
        unless res_klass <= Net::HTTPRedirection
          raise EOFError if (!params[:request].is_a?(Net::HTTP::Head)) && @response.content_length() && @response.content_length() != total
        end

        @response.each_header { |k,v|
          Mechanize.log.debug("response-header: #{ k } => #{ v }")
        } if Mechanize.log

        params[:response_body] = body
        params[:res_klass] = res_klass
        super
      end
    end
  end
end
