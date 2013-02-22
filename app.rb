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
  headers.merge default_headers
  secret = "#{csrf_token}--#{SECRET}"
  @om = OriginMap::Container.new(secret)
  @om.data = {url: request.path}
  layout('
<script type="text/javascript">

XSS..

</script>')
end
