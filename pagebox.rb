require 'json'
require 'base64'

module Pagebox

  class Box
    attr_accessor :data

    def initialize(secret)
      @secret = secret
      @verifier = MessageVerifier.new(@secret)
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
      @data = ["default"]
    end

    def meta_tag
      '<meta name="pagebox" content="'+generate+'" />'
    end

    def permit?(scope)
      @data.include? scope.to_s
    end
  
    def <<(*vals)
      @data.push *vals
    end
  end

  class Preflight
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      if env["REQUEST_METHOD"] == 'OPTIONS'
        # XHR preflight - Allow anything
        puts "Allow XHR"
        return [200, permit_headers({}), ['Access granted!']]
      else
        # actual request (GET/POST) can be XHR or normal browser navigation
        puts "Cookie received #{request.cookies}"
        pagebox_token = request.cookies["pagebox_token"] || begin
          puts 'set new cookie'
          set_token = true
          SecureRandom.base64(30)
        end
        pagebox_secret = "#{pagebox_token}--#{PAGEBOX_SECRET}"
        env['pagebox'] = Box.new(pagebox_secret)
        puts "Now use #{pagebox_secret} secret"

        input_pagebox = env["HTTP_PAGEBOX"] || request.params['pagebox']

        permitted = if input_pagebox
          begin
            env['pagebox'].verify(input_pagebox.to_s)
            puts 'loaded pagebox', env['pagebox'].data
            permitted_list = env['pagebox'].data

            permit?(request, env['pagebox'])
          rescue MessageVerifier::InvalidSignature
            return error 'Malformed pagebox'
          end 
        else
          false
        end

        puts "Granted #{permitted} #{request.path} for #{env['pagebox'].data}"

        # now we clean and build new pagebox
        env['pagebox'].build!

        if env['REQUEST_METHOD'] == 'GET'
          # READ
          response = @app.call(env)
        else
          # WRITE
          if permitted
            response = @app.call(env)
          else
            return error(input_pagebox ? 
              "Pagebox provided but doesn't permit this action. Allowed: #{permitted_list}" : 
              "Pagebox not found")
          end
        end

      
        rr = Rack::Response.new(response[2],response[0],response[1])


        default_headers(rr.headers, request.path == '/pageboxproxy')
        # allow XHR to read response if permitted
        permit_headers(rr.headers) if permitted


        rr.set_cookie("pagebox_token",
                          value: pagebox_token,
                          path: "/",
                          httponly: true) if set_token

        rr
      end
    end

    def error(text)
      puts "ERROR: #{text}"
      [500, default_headers('Content-Type'=>'application/json'), [JSON.dump({error: text})]]
    end
  end



  # rails - like
  class MessageVerifier
    class InvalidSignature < StandardError; end

    def initialize(secret, options = {})
      @secret = secret
      @digest = options[:digest] || 'SHA1'
      @serializer = options[:serializer] || JSON
    end

    def verify(signed_message)
      raise InvalidSignature if signed_message.empty?

      data, digest = signed_message.split("--")
      if data && digest && compare(digest, generate_digest(data))
        @serializer.load(::Base64.decode64(data))
      else
        raise InvalidSignature
      end
    end

    def compare(a,b)
      a.hash == b.hash && a == b
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