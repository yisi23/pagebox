require 'sinatra'
require './pagebox'
require './preflight'
require 'securerandom'

#pagebox secret
PAGEBOX_SECRET = 'abcdabcdabcdabcdabcdabcdabcdabcdabcd'

before do
  @pb = request.env['pagebox']
end

disable :protection
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

<iframe sandbox="allow-scripts  allow-top-navigation allow-forms allow-popups allow-same-origin" src="/pageboxproxy"></iframe>
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
  This is /about page, you are not supposed to pay from here. This page is XSS vulnerable. Try to pay from here using js console

<pre>
x=new HttpRequest;
x.open('get','payments/new');
x.setRequestHeader('Pagebox',pagebox());
x.withCredentials = true;
x.send();

<iframe src="/payments/new"></iframe>

x=window.open('/payments')

<form method="post" action="/payments">
<input name="pagebox" value="#{@pb.generate}">
<input type=submit>
</form>

</pre>
HTML
end


get '/pageboxproxy' do
  # do all given in postMessage
  return r=<<HTML
<!doctype html>
<html>
<head>
<script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
</head>
<body>
pb proxy
<script>

var callbacks = {}
window.onmessage = function(e){
  window.e = e;
  document.write(e.data)
  var x=new XMLHttpRequest;
  x.open('get','payments/new');
  x.withCredentials = true;
  x.send();
}

</script>
</body>
</html>
HTML

end