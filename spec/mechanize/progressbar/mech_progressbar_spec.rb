
describe MechanizeProgressBarAPI do

  before :all do
    @url = 'http://uri.host/uri.path'
    @headers_and_body = {
      :headers => {'Content-Length' => 1000},
      :body => 'a'*1000
    }
  end

  before :each do
    WebMock.reset!
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
      expect(progressbar).to work_fine
    end

    it "with block" do
      @agent.progressbar(:out => @output){@agent.get(@url)}
      expect(progressbar).to work_fine
    end

    describe "included/extended use" do
      it "accepts agent as agent" do
        o = Object.new
        o.extend(MechanizeProgressBarAPI)
        backup = $stderr
        $stderr = @output
        o.progressbar(@agent){@agent.get(@url)}
        $stderr = backup
        expect(progressbar).to work_fine
      end

      it "accepts (agent, pbar_opt) arguments" do
        o = Object.new
        o.extend(MechanizeProgressBarAPI)
        o.progressbar(@agent, :out => @output){@agent.get(@url)}
        expect(progressbar).to work_fine
      end
    end

    describe "method chain" do
      it "works fine" do
        @agent.progressbar(:out => @output).get(@url)
        expect(progressbar).to work_fine
      end

      it "options to method chain are reseted next time" do
        out1 = StringIO.new
        @agent.progressbar(:out => out1, :title => 'AAAA').get(@url)
        expect(out1.string).to match(/AAAA/)

        out2 = StringIO.new
        @agent.progressbar(:out => out2, :title => 'BBBB').get(@url)
        expect(out2.string).to match(/BBBB/)

        out3 = StringIO.new
        @agent.progressbar(:out => out3).get(@url)
        expect(out3.string).to_not match(/BBBB/)
      end
    end

    it "default ProgressBar title is uri.host" do
      @agent.progressbar(:out => @output){@agent.get(@url)}
      expect(progressbar).to work_fine
      expect(progressbar).to match(/uri.host/)
    end

    it "agent.progressbar(:title => 'new title') changes title" do
      new_title = 'new title'
      @agent.progressbar(:title => new_title, :out => @output){@agent.get(@url)}
      expect(progressbar).to work_fine
      expect(progressbar).to match(/#{new_title}/)
    end

    it "single mode title is 13 bytes" do
      str15 = '123456789012345'
      @agent.progressbar(:title => str15, :out => @output, :single => true){@agent.get(@url)}
      expect(progressbar).to match(/1234567890123:/)
    end

    it "default ProgressBar total is response['content-length']" do
      @agent.progressbar(:out => @output){@agent.get(@url)}
      expect(progressbar).to work_fine
      expect(progressbar).to match(/1000B/)
    end

    it "agent.progressbar(:total => 999) changes total filesize" do
      # TODO:
      @agent.progressbar(:total => 999, :out => @output){
        expect(lambda{@agent.get(@url)}).to_not raise_error
      }
      expect(progressbar).to work_fine
      expect(progressbar).to match(/999B/)
    end

    it "agent.progressbar(:out => io) changes output to io object" do
      @agent.progressbar(:out => @output){
        expect(lambda{@agent.get(@url)}).to_not raise_error
      }
      expect(progressbar).to work_fine
    end

    it "agent.progressbar(:format => fmtstr) changes output format" do
      fmt = "%-14s!%3d%% %s %s"
      str15 = '123456789012345'
      @agent.progressbar(:title => str15, :format => fmt, :out => @output, :single => true){@agent.get(@url)}
      expect(progressbar).to match(/1234567890123:!/)
    end

    it "agent.progressbar(:format_arguments => fmtarg) changes bar view" do
      stat = /uri\.host:      100% \|o+\| Time:\s+0:00:00/
      @agent.progressbar(:out => @output, :single => true){@agent.get(@url)}
      expect(progressbar).not_to match(stat)

      fmtarg = [:title, :percentage, :bar, :stat]
      @agent.progressbar(:format_arguments => fmtarg, :out => @output, :single => true){@agent.get(@url)}
      expect(progressbar).to match(stat)
    end

    it "when Exception occurs before fetching, raise it and show nothing" do
      WebMock.stub_request(:get, @url).to_timeout
      error = Net::HTTP::Persistent::Error
      error_message = /execution expired - Timeout::Error/

      @agent.progressbar(:output => @output) do
        expect(lambda{ @agent.get(@url) }).to raise_error(error, error_message)
      end
      expect(progressbar).to be_empty
    end

    ## TODO: it requires a webmock adapter for net-http-persistent
    # it "when HTTP status error occurs in reading, raise it and show nothing" do
    #   WebMock.stub_request(:get, @url).to_raise(Errno::ECONNREFUSED)
    #   lambda{
    #     @agent.progressbar{ @agent.get(@url)}
    #   }.should raise_error(Net::HTTP::Persistent::Error) # raises ECONNREFUSED
    # end

    it "when HTTP status error occurs after fetching, raise it and show nothing" do
      url_404 = 'http://host/404'
      WebMock.stub_request(:get, url_404).to_return(:status => ['404', 'Not Found'])
      expect(lambda{
        @agent.progressbar(:output => @output) do
          @agent.get(url_404)
        end
      }).to raise_error(Mechanize::ResponseCodeError)
      expect(progressbar).to be_empty
    end

    describe "with Logger" do

      before :all do
        require 'logger'
      end

      before :each do
        @out = StringIO.new
        @agent.log = Logger.new(@out)
      end

      def progressbar
        @out.string
      end

      it "{:suppress_logger => true} does nothing when no logger" do
        @agent.log = nil
        @agent.progressbar(:output => @out, :suppress_logger => false){@agent.get(@url)}
        expect(progressbar).to work_fine
        expect(progressbar).to_not match(/Read 1000 bytes/)
      end

      it "When Logger and ProgressBar have same outputs, Log output is suppressed " do
        @agent.progressbar(:output => @out){@agent.get(@url)}
        re = /^D, \[.+^http:\/\/.+?Time:\s+\d:\d\d:\d\d\n\Z/m
        # matches:
        ### D, [2011-06-29...
        ### http://uri.host//uri.path...
        ### ...
        ### (showing progressbar)
        ### ...
        ### ...1000B 195.7KB/s Time: 00:00:00\n
        expect(progressbar).to match(re)
      end

      it "When Logger output is diffrent from ProgressBar one, Mechanize shows Log as usual" do
        logger_out = StringIO.new
        @agent.log = Logger.new(logger_out)
        @agent.progressbar(:output => @out){@agent.get(@url)}

        expect(progressbar).to work_fine
        expect(progressbar).to_not match(/Read 1000 bytes/)
        expect(logger_out.string).to match(/Read 1000 bytes/)
      end

      it "{:suppress_logger => false} crashes ProgressBar output" do
        @agent.progressbar(:output => @out, :suppress_logger => false){@agent.get(@url)}

        re = /D, \[.+?\] DEBUG -- : Read 1000 bytes \(1000 total\)\r?\n100% \|o+\|\s+1000B/

        # matches:
        ### D, [(date+time)] DEBUG -- : Read 1000 bytes
        ### 100% |ooooooooooooooooooooooooooooooooooooooo|   1000B nnn.nKB/s Time: 00:00:00
        expect(progressbar).to match(re)
      end
    end
  end
end

