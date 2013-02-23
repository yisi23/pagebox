require 'sinatra'
require './pagebox'
require './preflight'
require 'securerandom'

#pagebox secret
PAGEBOX_SECRET = 'abcdabcdabcdabcdabcdabcdabcdabcdabcd'

before do
  @pb = request.env['pagebox']
end


enable :sessions

def layout(body)
  return r=<<HTML
<!doctype html>
<html>
<head>
<script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
<script src="/pagebox.js"></script>
<title>Pagebox demo</title>
#{@pb.meta_tag}
</head>
<body>
<h1> Pagebox </h1>
#{body}
<script>
pb_log();
</script>
</body>
</html>
HTML
end

get '/payments/new' do
  @pb << :payments

  layout("This is payment page, feel free to pay from here - POST to /payments")
end

post '/payments' do
  "PAID"
end


get '/about' do
  @pb << :static

  layout r=<<HTML
  This is about page, you cannot pay from here
<script type="text/javascript">
window.onload=function(){

/*
x=new HttpRequest;
x.open('get','payments/new?omap=adsf');
x.send('ffffff');
*/
}

</script>
HTML
end
