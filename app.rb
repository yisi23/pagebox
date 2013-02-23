require 'sinatra'
require './originmap'
require './preflight'
require 'securerandom'

SECRET = 'abcd'



=begin

if env['QUERY_STRING'].include?('origin_map=')
        # must be last param, for now
        origin_map = env['QUERY_STRING'].split('origin_map=').last
        # check integrity and access ..
        puts 'Checking integrity of', origin_map

        if true

          [200, heads, ['Access granted!']]
        end
      end
=end

# URL -based
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

def secret 
  "#{csrf_token}--#{SECRET}"
end

def layout(body)
  return r=<<HTML
<!doctype html>
<html>
<head>
<script src="/origin_map.js"></script>
<title>OriginMap demo</title>
#{@omap.meta_tag}
</head>
<body>
<h1>OriginMap</h1>
#{body}
</body>
</html>
HTML
end

before do
end

get '/payments/new' do
  layout("Your payments #{request.env}")
end

post '/payments' do
  #PAYMENT!



  #request.xhr?.to_s
  

end


get '/about' do
  val = 'Sandbox allow-scripts allow-top-navigation allow-forms'
  headers["Content-Security-Policy"]=val
  headers["X-WebKit-CSP"]=val

  @omap.permit! :static
  layout r=<<HTML
<script type="text/javascript">
window.onload=function(){
var x=new XMLHttpRequest;x.open('get','payments/new');x.send();

}

</script>
HTML
end
