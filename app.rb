require 'sinatra'
require './originmap'
require 'securerandom'


class Preflight
  def initialize(app)
    @app = app
  end

  def call(env)
    heads = {'Access-Control-Allow-Origin' => '*', 
            'Access-Control-Allow-Headers' => 'Origin-Map,X-CSRF-Token,Content-Type'}
   
    puts 'Received ENV', env
    # request from sandbox and XHR
    if env['HTTP_ORIGIN'] == 'null' and !env['HTTP_ORIGIN_MAP']
      #env["REQUEST_METHOD"] == 'OPTIONS'
      if env['QUERY_STRING'].include?('origin_map=')
        # must be last param, for now
        origin_map = env['QUERY_STRING'].split('origin_map=').last
        # check integrity and access ..
        puts 'Checking integrity of', origin_map

        if true

          [200, heads, ['Access granted!']]
        end
      end
    else
      resp = @app.call(env)
      resp[1].merge!(heads)
      puts 'response', resp[1]
      resp
    end
  end
end


SECRET = 'abcd'
default_headers = {
  "Content-Security-Policy" => 'sandbox;',
  "X-XSS-Protection" => '0;'
}


def map_origin(path)
  case path

  when '/about'
    :no
  else
    :default
  end
end



def csrf_token
  session[:_csrf_token] == SecureRandom.base64(30)
end

def layout(body)
  return r=<<HTML
<!doctype html>
<html>
<head>
<title>OriginMap demo</title>
#{@om}
</head>
<body>
<h1>OriginMap</h1>
#{body}
</body>
</html>
HTML
end

get '/payments/new' do


  layout("Your payments#{request.env}")
end

post '/payments' do
  #PAYMENT!



  #request.xhr?.to_s
  

end


get '/about' do
  val = 'Sandbox allow-scripts allow-top-navigation allow-forms'
  headers["Content-Security-Policy"]=val
  headers["X-WebKit-CSP"]=val

  secret = "#{csrf_token}--#{SECRET}"
  @om = OriginMap::Container.new(secret)
  @om.data = {url: request.path}
  layout r=<<HTML
<script type="text/javascript">
window.onload=function(){
var x=new XMLHttpRequest;x.open('get','payments/new');x.send();

}

</script>
HTML
end
