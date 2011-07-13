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
