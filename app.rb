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

Try POST to payments <form method="post" action="/payments">
<input name="pagebox" type="hidden" value="@pb.generate">
<input type=submit>
</form>
Try POST to /order_pizza <form method="post" action="/order_pizza">
<input name="pagebox" type="hidden" value="@pb.generate">
<input type=submit>
</form>
Try GET (navigate) to /payments/new <form method="get" action="/payments/new">
<input type=submit>
</form>
Try GET (navigate) to /about <form method="get" action="/about">
<input type=submit>
</form>

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

  layout("This is payment page, feel free to pay from here - POST to /payments. You cannot order pizza from here, no way!!!")
end

post '/payments' do
  "PAID"
end

post '/order_pizza' do
  "PERFEKTO!"
end


get '/about' do
  @pb << :order_pizza

  layout r=<<HTML
  This is /about page, you are not supposed to pay from here, you can only order pizza.
<pre>
This XHR doesnt send cookies :(
x=new HttpRequest;
x.open('get','/payments/new');
x.setRequestHeader('Pagebox',pagebox());
x.withCredentials = true;
x.send();
You cannot read data from frame:<br> 
<iframe src="/payments/new"></iframe>
</pre>
HTML
end


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