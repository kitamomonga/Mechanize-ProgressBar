# is for Mechanize 1.0.0 only
class Mechanize   # has 6 added/modified lines
  include MechanizeProgressBarAPI # (1of6)a
  class Chain
    class ResponseReader
      def handle(ctx, params)
        params[:response] = @response
        body = StringIO.new
        total = 0
        mpbar = MechanizeProgressBar.new(params[:agent], params[:request], params[:response]) # (2of6)a
        @response.read_body { |part|
          total += part.length
          body.write(part)
          # Mechanize.log.debug("Read #{total} bytes") if Mechanize.log
          Mechanize.log.debug("Read #{total} bytes") if Mechanize.log && !mpbar.suppress_logger? # (3of6)m
          mpbar.inc(part.length) # (4of6)a
        }
        body.rewind
        mpbar.finish # (5of6)a
        Mechanize.log.debug("Read #{total} bytes") if Mechanize.log && !mpbar.suppress_logger? # (6of6)a
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
