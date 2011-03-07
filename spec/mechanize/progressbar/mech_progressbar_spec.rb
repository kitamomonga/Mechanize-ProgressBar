require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

### NOTE: On MechanizeProgressBarAPI - "accepts agent as agent" spec, we swap $stderr.

describe MechanizeProgressBarAPI do

  before :all do
    @url = 'http://uri.host/uri.path'
    @headers_and_body = {
      :headers => {'Content-Length' => 1000},
      :body => 'a'*1000
    }
  end

  before :each do
    WebMock.stub_request(:get, @url).to_return(@headers_and_body)
  end

  describe "#progressbar" do

    def progressbar
      @output.string
    end

    RSpec::Matchers.define :work_fine do
      match do |actual|
        /oooooooo+/ =~ actual
      end
    end

    before :each do
      @agent = Mechanize.new
      @output = StringIO.new
    end
    it "accepts Hash as ProgressBar option" do
      @agent.progressbar(:out => @output){@agent.get(@url)}
      progressbar.should work_fine
    end

    it "accepts agent as agent" do
      o = Object.new
      o.extend(MechanizeProgressBarAPI)
      backup = $stderr
      $stderr = @output
      o.progressbar(@agent){@agent.get(@url)}
      $stderr = backup
      progressbar.should work_fine
    end

    it "accepts (agent, pbar_opt) arguments" do
      o = Object.new
      o.extend(MechanizeProgressBarAPI)
      o.progressbar(@agent, :out => @output){@agent.get(@url)}
      progressbar.should work_fine
    end

    it "with block" do
      @agent.progressbar(:out => @output){@agent.get(@url)}
      progressbar.should work_fine
      @agent.pre_connect_hooks.should be_empty
      @agent.post_connect_hooks.should be_empty
    end

    it "method chain leaves a proc on post_connect_hooks" do
      @agent.progressbar(:out => @output).get(@url)
      progressbar.should work_fine
      @agent.pre_connect_hooks.should be_empty
      @agent.post_connect_hooks.should_not be_empty
    end

    it "default ProgressBar title is uri.host" do
      @agent.progressbar(:out => @output){@agent.get(@url)}
      progressbar.should work_fine
      progressbar.should match(/uri.host/)
    end

    it "agent.progressbar(:title => 'new title') changes title" do
      new_title = 'new title'
      @agent.progressbar(:title => new_title, :out => @output){@agent.get(@url)}
      progressbar.should work_fine
      progressbar.should match(/#{new_title}/)
    end

    it "single mode title is 13 bytes" do
      str15 = '123456789012345'
      @agent.progressbar(:title => str15, :out => @output, :single => true){@agent.get(@url)}
      progressbar.should match(/1234567890123:/)
    end

    it "default ProgressBar total is response['content-length']" do
      @agent.progressbar(:out => @output){@agent.get(@url)}
      progressbar.should work_fine
      progressbar.should match(/1000B/)
    end

    it "agent.progressbar(:total => 999) changes total filesize" do
      # TODO:
      @agent.progressbar(:total => 999, :out => @output){
        lambda{@agent.get(@url)}.should_not raise_error
      }
      progressbar.should work_fine
      progressbar.should match(/999B/)
    end

    it "default ProgressBar out is $stderr" do
      # TODO:
    end

    it "agent.progressbar(:out => io) changes output to io object" do
      @agent.progressbar(:out => @output){
        lambda{@agent.get(@url)}.should_not raise_error
      }
      progressbar.should work_fine
    end

    it "agent.progressbar(:format => fmtstr) changes output format" do
      fmt = "%-14s!%3d%% %s %s"
      str15 = '123456789012345'
      @agent.progressbar(:title => str15, :format => fmt, :out => @output, :single => true){@agent.get(@url)}
      progressbar.should match(/1234567890123:!/)
    end

    it "agent.progressbar(:format_arguments => fmtarg) changes bar view" do
      stat = "uri.host:      100% |oooooooooooooooooooooooooooooooooooooooooo| Time: 00:00:00"
      @agent.progressbar(:out => @output, :single => true){@agent.get(@url)}
      progressbar.should_not be_include(stat)

      fmtarg = [:title, :percentage, :bar, :stat]
      @agent.progressbar(:format_arguments => fmtarg, :out => @output, :single => true){@agent.get(@url)}
      progressbar.should be_include(stat)
    end

    it "when HTTP status error occurs in Mechanize, rescue unregister" do
      url_404 = 'http://host/404'
      WebMock.stub_request(:get, url_404).to_return(:status => ['404', 'Not Found'])
      lambda{
        @agent.progressbar(:output => @output) do
          @agent.pre_connect_hooks[0].should be_kind_of(Proc)
          @agent.get(url_404)
        end
      }.should raise_error(Mechanize::ResponseCodeError)
      @agent.pre_connect_hooks.should be_empty
      progressbar.should be_empty
    end

    it "when Exception occurs in Mechanize, rescue unregister" do
      WebMock.stub_request(:get, @url).to_timeout
      @agent.progressbar(:output => @output) do
        @agent.pre_connect_hooks[0].should be_kind_of(Proc)
        lambda{@agent.get(@url)}.should raise_error(Timeout::Error)
      end
      @agent.pre_connect_hooks.should be_empty
      progressbar.should be_empty
    end

    it "Mechanize Logger output to $stderr crashes ProgressBar" do
      require 'logger'
      out = StringIO.new
      @agent.log = Logger.new(out)
      @agent.progressbar(:output => out){@agent.get(@url)}

      # matches:
      ### http://uri.host/uri.path
      ### D, [(date+time)] DEBUG -- : Read 1000 bytes ETA:  --:--:--
      ### 100% |ooooooooooooooooooooooooooooooooooooooo|   1000B nnn.nKB/s Time: 00:00:00
      re = /http:\/\/uri\.host\/uri\.path\s+D, \[.+?\] DEBUG -- : Read 1000 bytes\s+100% |o+|\s+1000B/
      out.string.should match(re)
    end

    it "(:suppress_logger => true) make ProgressBar and Mechanize Logger output independent" do
      require 'logger'
      out = StringIO.new
      @agent.log = Logger.new(out)
      @agent.progressbar(:output => out, :suppress_logger => true){@agent.get(@url)}

      # matches:
      ### request-header: keep-alive => 300\n
      ### http://uri.host/uri.path
      before_progressbar = /request-header: (.+?) => (.+?)\s+http:\/\/uri\.host\/uri\.path/
      out.string.should match(before_progressbar)

      # matches:
      ### 100% |ooooooooooooooooooooooooooooooooooooooo|   1000B 151.5KB/s Time: 00:00:00
      ### D, [(date+time)] DEBUG -- : Read 1000 bytes
      after_progressbar = /100%\s*\|o+\|\s+1000B (.+?)B\/s Time: \d\d:\d\d:\d\d\s+D, \[.+?\] DEBUG -- : Read 1000 bytes/
      out.string.should match(after_progressbar)
    end

  end
end


