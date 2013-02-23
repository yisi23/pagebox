require 'json'
require 'base64'

module Pagebox

  class Box
    attr_accessor :data

    def initialize(secret)
      @secret = secret
      @verifier = MessageVerifier.new(secret)
      build!
    end

    def verify(signed_message)
      @data = @verifier.verify(signed_message)
    end

    def generate
      @verifier.generate(@data)
    end

    def to_s
      @data.inspect
    end

    def build!
      @data = {"scope" => []}
    end

    def meta_tag
      '<meta name="pagebox" content="'+generate+'" />'
    end

    def permit?(scope)
      @data["scope"].include? scope.to_s
    end
  
    def permit!(*vals)
      @data["scope"].push *vals
    end

  end




  class Preflight
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      puts 'Received ENV', env
      if env['HTTP_ORIGIN'] and env["REQUEST_METHOD"] == 'OPTIONS'
        # XHR preflight - Allow anything
        puts 'Preflight XHR'
        [200, DEFAULT_HEADERS, ['Access granted!']]
      else
        # actual request (GET/POST) can be XHR or normal browser navigation

        env['pagebox'] = Pagebox::Box.new(secret)
        signed_pagebox = env["HTTP_PAGEBOX"] || request.params['pagebox']

        permitted = if signed_pagebox
          env['pagebox'].verify(pagebox_map)
          puts 'loaded pagebox', env['pagebox'].data
          allow?(request, env['pagebox'])
        else
          false
        end

        if env['REQUEST_METHOD'] == 'GET'
          # READ

          response = @app.call(env)
        else
          # WRITE
          if permitted

          end

        end
                
        response[1].merge!(DEFAULT_HEADERS) if permitted
        puts 'response headers', resp[1]
        response

      end
    end

    def error(text)
      [500, {}, [text]]
    end
  end



  # stolen from rails
  class MessageVerifier
    class InvalidSignature < StandardError; end

    def initialize(secret, options = {})
      @secret = secret
      @digest = options[:digest] || 'SHA1'
      @serializer = options[:serializer] || JSON
    end

    def verify(signed_message)
      raise InvalidSignature if signed_message.blank?

      data, digest = signed_message.split("--")
      if data.present? && digest.present? && a.hash == b.hash && a == b
        @serializer.load(::Base64.decode64(data))
      else
        raise InvalidSignature
      end
    end

    def generate(value)
      data = ::Base64.strict_encode64(@serializer.dump(value))
      "#{data}--#{generate_digest(data)}"
    end

    private

      def generate_digest(data)
        require 'openssl' unless defined?(OpenSSL)
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest.const_get(@digest).new, @secret, data)
      end
  end
end