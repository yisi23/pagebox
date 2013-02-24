require 'sinatra'
require './pagebox'
require './preflight'
require 'securerandom'


disable :protection
enable :sessions

PAGEBOX_SECRET = 'abcdabcdabcdabcdabcdabcdabcdabcdabcd'

before do
  @pb = request.env['pagebox']
end

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
Hint: JS function pagebox() returns current pagebox, provide it as param "pagebox" or as request header 'Pagebox'
<form method="post" action="/payments">
<input name="pagebox" type="hidden" value="#{@pb.generate}">
<input type=submit value="Try POST to /payments">
</form>

<form method="post" action="/payments?postback=1">
<input name="pagebox" type="hidden" value="#{@pb.generate}">
<input type=submit value="Try POST READ to /payments">
</form>

<form method="post" action="/payments/finish">
<input name="pagebox" type="hidden" value="#{@pb.generate}">
<input type=submit value="Try POST to /payments/finish">
</form>

<form method="post" action="/order_pizza">
<input name="pagebox" type="hidden" value="#{@pb.generate}">
<input type=submit value="Try POST to /order_pizza">
</form>

<form method="get" action="/payments/new">
<input type=submit value="Try GET (navigate) to /payments/new">
</form>

<form method="get" action="/about">
<input type=submit value="Try GET (navigate) to /about">
</form>

    #{body}
    <script>
    pb_log();
    </script>

  </body>
</html>
HTML
end

get '/' do
  layout '
Demo of <a href="https://github.com/homakov/pagebox/">Pagebox technique</a><br/>
Pagebox allows you only:<br>
POST at /payments from /payments/new<br>
POST at /payments/finish after POST to /payments<br>
POST at /order_pizza from /about<br>
Try to bypass and pay from /about, it is vulnerable to XSS!<br>
P.S. Your browser should support Content Security Policy<br>'
end

get '/payments/new' do
  @pb << :payments

  layout("This is payment page, feel free to pay from here - POST to /payments. You cannot order pizza from here, no way!!!")
end

post '/payments' do
  @pb << :finish
  layout "PAID"
end

post '/payments/finish' do
  layout "FINISHED"
end

post '/order_pizza' do
  layout "PERFEKTO!"
end


get '/about' do
  @pb << :order_pizza

  layout r=<<HTML
  This is /about page, you are not supposed to pay from here, you can only order pizza.
<pre>

This XHR doesnt send cookies :(
<br>
<textarea rows=20 cols=60 id="execute">
x=new HttpRequest;
x.open('get','/payments/new');
x.setRequestHeader('Pagebox',pagebox());
x.withCredentials = true;
x.send();
</textarea>
<br>
<button onclick="eval(execute.innerHTML)">Run!</button>

You cannot read data from this frame:<br> 
<iframe src="/payments/new"></iframe>


</pre>
HTML
end

=begin

get '/pageboxproxy' do
  # XHR received from postMessage
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
  x.open('get','/payments/new');
  x.withCredentials = true;
  x.send();
}

</script>
</body>
</html>
HTML

end
=end