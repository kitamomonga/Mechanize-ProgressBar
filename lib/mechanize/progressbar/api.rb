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
