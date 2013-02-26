class Preflight < Pagebox::Preflight
  # Request method, Target, Allowed origins
  get %r{/[a-z]+/pay}, ['/payments/new']
  get %r{/[a-z]+/pay2}, ->target,origin{ true }
  get '/messages.json', from: [%r{/[a-z]+/private_messages}]
  get '/some_data', '/payments/new'

  post '/payments', ['/payments/new']
  post '/payments/finish', from: '/payments'

  add_rule 'PATCH', %r{/payments/\d+/update}, %r{/payments/\d+}
  add_rule '*', %r{/payments/\d+/delete}, %r{/payments/\d+}



  def default_headers(h, sameorigin = false)
    val = 'Sandbox allow-scripts  allow-top-navigation allow-forms allow-popups'
    val << ' allow-same-origin' if sameorigin
    #val = '' if sameorigin
    val << ";script-src 'self' 'unsafe-inline' http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js ;"
    val<<";report-uri /reportcom"
    #  script-nonce random-value; CSP from twitter??
    h["Content-Security-Policy"] = h["X-Content-Security-Policy"] = h["X-WebKit-CSP"] = val
#reflected-xss

    h
  end
  
  def permit_headers(h)    
    h['Access-Control-Allow-Origin'] = 'null' 
    h['Access-Control-Allow-Methods'] = 'POST,GET,OPTIONS' 
    h['Access-Control-Allow-Headers'] = 'accept, origin, x-requested-with, content-type,pagebox,Cookie,X-CSRF-Token'
    h['Access-Control-Allow-Credentials']='true'
    h
  end


  
=begin
Second, it can be used to embed content from a third-party site, sandboxed to prevent that site from opening pop-up windows, etc, without preventing the embedded page from communicating back to its originating site, using the database APIs to store data, etc.
  var x=new XMLHttpRequest;
  x.open('get','/about');
  x.setRequestHeader('Pagebox',pagebox())
  x.withCredentials = true;
  x.send();
=end
  
end