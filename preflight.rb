#require 'rack/request'

DEFAULT_HEADERS = {'Access-Control-Allow-Origin' => '*', 
                  'Access-Control-Allow-Headers' => 'Cookie,Origin-Map,X-CSRF-Token,Content-Type',
                  "X-XSS-Protection" => '0;'}

val = 'Sandbox allow-scripts allow-top-navigation allow-forms'
DEFAULT_HEADERS["Content-Security-Policy"]=val
DEFAULT_HEADERS["X-WebKit-CSP"]=val

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

      map = env['omap'] = Pagebox::Container.new(secret)
      signed_map = env["HTTP_PAGEBOX"] || request.params['pagebox']
      if signed_map 
        puts 'now verify' 
        map.verify(signed_map)
      end



      if env['HTTP_ORIGIN']
        #  == 'null'
        # watson, this is POST, must have omap
        unless properly_signed_map
          
          return error('Pagebox not found')
          
        end

      else

        # this is GET request. Must have omap *ONLY* to get ACAO: '*'
        # otherwise it won't be able to read response
       

      end
      
      # Input origin map

      response = @app.call(env)
      if properly_signed_map
        response[1].merge!(DEFAULT_HEADERS) 
        puts 'response headers', resp[1]
      end
      response
    end
  end

  def error(text)
    [500, {}, [text]]
  end
end