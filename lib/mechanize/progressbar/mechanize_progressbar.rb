class MechanizeProgressBar # :nodoc:

  def self.register(mech, pbar_opts)
    unregister(mech)
    mech.progressbar_option.update(pbar_opts)

    reset_reservation = mech.progressbar_option['reserve!']
    mech.progressbar_option['reset!'] = reset_reservation
  end

  def self.unregister(mech)
    mech.progressbar_option.clear
  end

  def self.unregister_next_init(mech)
    mech.progressbar_option['reserve!'] = true
  end

  def initialize(mech, request, response)
    pbar_opts = mech.progressbar_option
    self.class.unregister(mech) if pbar_opts['reset!']

    _first_time = pbar_opts.empty?
    _unusual_response = response.code != '200'

    case
    when _first_time, _unusual_response
      @progressbar = nil
    else
      @progressbar = progressbar_new(pbar_opts, request, response)
    end

    if mech.log
      log_output = mech.log.instance_variable_get(:@logdev).dev
      pbar_output = @progressbar.instance_variable_get(:@out)
      @suppress_logger = true if log_output == pbar_output
    end

    @suppress_logger = pbar_opts[:suppress_logger] if pbar_opts.has_key?(:suppress_logger)
  end

  def inc(step)
    @progressbar.inc(step) if @progressbar
  end

  def finish
    @progressbar.finish if @progressbar
  end

  def suppress_logger?
    @suppress_logger
  end

  private

  def progressbar_new(pbar_opts, request, response)
    out = pbar_opts[:out] || pbar_opts[:output] || $stderr
    if pbar_opts[:single] then
      title = pbar_opts[:title] || request['Host']
      format = pbar_opts[:format]
      format_arguments = pbar_opts[:format_arguments]
    else
      title = pbar_opts[:title] || ""
      format = pbar_opts[:format] || "%3d%% %s %s"
      format_arguments = pbar_opts[:format_arguments] || [:percentage, :bar, :stat_for_file_transfer]
      out.print "#{pbar_opts[:title]||uri(request)}\n"
    end
    total = pbar_opts[:total] || filesize(response)
    pbar_class = pbar_opts[:reversed] ? ReversedProgressBar : ProgressBar

    progressbar = pbar_class.new(title, total, out)

    progressbar.file_transfer_mode unless pbar_opts[:file_transfer_mode]
    progressbar.format = format if format
    progressbar.format_arguments = format_arguments if format_arguments
    progressbar
  end

  def filesize(response)
    content_length = response['content-length']
    content_length ? content_length.to_i : 0
  end

  def uri(request)
    scheme = request.class.to_s =~ /https/i ? 'https' : 'http'
    URI.parse("#{scheme}://#{request['Host']}#{request.path}").to_s
  end

end
