require 'sinatra'



get '/' do
  return r=<<HTML
<!doctype html>
<html>
<head>
<title>Sakurity</title>
</head>
<body>
<h1>Sakurity</h1>
<div style="">Make your website <i>sakure</i>: <a href="mailto:homakov@gmail.com">homakov@gmail.com</a></div>

<script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-38702231-1']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>
</body>
</html>
HTML
end
