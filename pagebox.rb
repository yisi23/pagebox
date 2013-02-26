require 'json'
require 'base64'
require 'cgi'
require 'stringio'
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
      @data = {
        "scope" => ["default"],
        "token" => nil,
        "url" => nil
      }
    end

    def meta_tag
      '<meta name="pagebox" content="'+generate+'" />'
    end

    def permit?(scope)
      @data['scope'].include? scope.to_s
    end
  
    def <<(*vals)
      @data['scope'].push *vals
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

            _pageboxqueue = request.params["_pageboxqueue"] #XHRProxy

            if _pageboxqueue
              env['rack.input'] = Rack::Lint::InputWrapper.new(StringIO.new(request.params['body']))
              env['CONTENT_LENGTH'] = Rack::Utils.bytesize(request.params['body'])
              env["CONTENT_TYPE"] = request.params['content_type'] if request.params['content_type']
              request = Rack::Request.new(env)
            end
            
            # we store it to show in error later
            old_pagebox = env['pagebox'].data

            permit?(request, env['pagebox'])
          rescue MessageVerifier::InvalidSignature
            return error 'Malformed pagebox'
          end 
        else
          false
        end

        puts "current rules", JSON.dump(@@rules)

        # now we clean and build new pagebox
        env['pagebox'].build!
        env['pagebox'].data['url'] = request.path
        env['pagebox'].data['token'] = pagebox_token

        if env['REQUEST_METHOD'] == 'GET'
          # READ
          response = @app.call(env)
        else
          # WRITE
          if permitted
            response = @app.call(env)
          else
            return error(input_pagebox ? 
              "Pagebox provided but URL is not included in allowed origins: #{allowed_origins_for(request.request_method, request.path)}. Pagebox: #{old_pagebox}" : 
              "Pagebox was not found")
          end
        end

      
        rr = Rack::Response.new(response[2],response[0],response[1])


        default_headers(rr.headers)
        
        # allow XHR to read response if permitted
        # permit_headers(rr.headers) 
        if permitted and _pageboxqueue

          body = JSON.dump({
            body: rr.body[0],
            status: rr.status,
            pagebox: input_pagebox,
            queue: _pageboxqueue,
            responseType: rr.headers['Content-Type']
          })
          body =<<BODY
<script>if(parent != window) parent.postMessage(#{body.gsub('<','\u003C')},"*");</script>
BODY
          return [200, {'content-length' => Rack::Utils.bytesize(body).to_s}, [body]]
        end



        rr.set_cookie("pagebox_token",
                          value: pagebox_token,
                          path: "/",
                          httponly: true) if set_token
        
        rr
      end
    end

    def error(text)
      puts "ERROR: #{text}"
      [423, default_headers('Content-Type'=>'application/json'), [JSON.dump({error: text})]]
    end

    def endpoint_permit?(method, target, origin)
      origins = allowed_origins_for(method, target)

      if origins.nil? 
        true # permit-by-default
      else
        origins.any?{|rule_origin| match?(origin, rule_origin)}
      end
    end

    def allowed_origins_for(method, target)
      @@rules.each do |rule|
        if rule[0] == method and match?(target, rule[1])
          return rule[2]
        end
      end
      nil
    end

    def match?(static, dynamic)
      dynamic.is_a?(Regexp) ? dynamic =~ static : dynamic == static
    end

    def self.get(target, origin)
      self.add_rule('GET', target, origin)
    end

    def self.post(target, origin)
      self.add_rule('POST', target, origin)
    end

    def self.add_rule(method, target, origin)
      @@rules ||= []
      if origin.is_a?(Hash)
        origin = origin[:from]
      end
      if origin.is_a?(String)
        origin = [origin]
      end
      @@rules.push([method, target, origin])
      puts 'added rule to ', @@rules
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