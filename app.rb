require 'sinatra'



get '/' do
  return r=<<HTML
<!doctype html>
<html>
<head>
<title>OriginMap</title>
</head>
<body>
<h1>OriginMap</h1>

<script type="text/javascript">

XSS..

</script>
</body>
</html>
HTML
end
