module MechanizeProgressBarAPI
  ### Usage:
  ###   require 'mechanize'
  ###   require 'mechanize/progressbar'
  ###   agent = Mechanize.new
  ###   agent.progressbar{ agent.get(large_file) }
  ###   agent.get(some_page) #=> shows nothing
  ###   agent.progressbar{ agent.page.link_with(:text => 'download here').click }
  ###
  ### If you want to set parameters to ProgressBar object,
  ###   agent.progressbar(:title => 'large_file', :format_arguments => @fmt) do
  ###     agent.get(large_file)
  ###   end
  ### ProgressBar is gem lib. Please install with 'gem install progressbar' or bundle.
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
  ### [:suppress_logger] stops Logger output in socket reading. default true when agent.log output and :out is same
  def progressbar(mech_or_pbar_opts = self, pbar_opts = {})
    if mech_or_pbar_opts.kind_of?(Hash) then
      mech, pbar_opts = self, mech_or_pbar_opts
    else
      mech = mech_or_pbar_opts
    end
    MechanizeProgressBar.register(mech, pbar_opts)
    if block_given?
      begin
        yield mech
      rescue Exception, StandardError
        MechanizeProgressBar.unregister(mech)
        raise
      end
      MechanizeProgressBar.unregister(mech)
    else
      MechanizeProgressBar.unregister_next_init(mech)
    end
    mech
  end

  def progressbar_option # :nodoc:
    @progressbar_option ||= {}
  end
end
