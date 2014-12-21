class Mechanize
  include MechanizeProgressBarAPI # (1of7)a
  class HTTP
    class Agent

      def response_read response, request, uri=nil
        content_length = response.content_length

        if use_tempfile? content_length then
          body_io = make_tempfile 'mechanize-raw'
        else
          body_io = StringIO.new.set_encoding(Encoding::BINARY)
        end

        total = 0
        mpbar = MechanizeProgressBar.new(self.context, request, response) # (2of7)a


        begin
          response.read_body { |part|
            total += part.length

            if StringIO === body_io and use_tempfile? total then
              new_io = make_tempfile 'mechanize-raw'

              new_io.write body_io.string

              body_io = new_io
            end

            body_io.write(part)
            # log.debug("Read #{part.length} bytes (#{total} total)") if log
            log.debug("Read #{part.length} bytes (#{total} total)") if log && !mpbar.suppress_logger? # (3of7)m
            mpbar.inc(part.length) # (4of7)a
          }
        rescue EOFError => e
          # terminating CRLF might be missing, let the user check the document
          raise unless response.chunked? and total.nonzero?

          body_io.rewind
          raise Mechanize::ChunkedTerminationError.new(e, response, body_io, uri,
                                                       @context)
        rescue Net::HTTP::Persistent::Error, Errno::ECONNRESET => e
          body_io.rewind
          raise Mechanize::ResponseReadError.new(e, response, body_io, uri,
                                                 @context)
        ensure # (5of7)a
          mpbar.finish # (6of7)a
        end

        body_io.flush
        body_io.rewind
        log.debug("Read #{total} bytes total") if log && !mpbar.suppress_logger? # (7of7)a

        raise Mechanize::ResponseCodeError.new(response, uri) if
          Net::HTTPUnknownResponse === response

        content_length = response.content_length

        unless Net::HTTP::Head === request or Net::HTTPRedirection === response then
          if content_length and content_length != body_io.length
            err = EOFError.new("Content-Length (#{content_length}) does not " \
                          "match response body length (#{body_io.length})")
            raise Mechanize::ResponseReadError.new(err, response, body_io, uri,
                                                    @context)
          end
        end

        body_io
      end
    end
  end
end
