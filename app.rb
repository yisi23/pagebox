require 'sinatra'
require './originmap'
require 'securerandom'

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
