require 'json'
require 'base64'

module OriginMap

  class Container
    attr_accessor :data

    def initialize(secret)
      @secret = secret
      @data = {"scope" => []}
      @verifier = MessageVerifier.new(secret)
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

    def meta_tag
      v = '<meta name="origin_map" content="'+generate+'" />'
      #v.respond_to? :html_safe ? v.html_safe : v 
    end

    def permit?(scope)
      @data["scope"].include? scope.to_s
    end
    
    def add!(*vals)
      @data["scope"].push *vals
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