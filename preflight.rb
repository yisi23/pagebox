class Preflight < Pagebox::Preflight

  def permit?(req, pagebox)
    case req.path
    when /\A\/payments/
      # serious business.
      pagebox.permit? :payments
    when '/order_pizza'
      pagebox.permit? :order_pizza
    else
      true # pagebox.permit? :basic
    end
  end

  def default_headers(h, sameorigin = false)
    val = 'Sandbox allow-scripts  allow-top-navigation allow-forms allow-popups'
    val << ' allow-same-origin' if sameorigin
    #val = '' if sameorigin

    h["Content-Security-Policy"] = val
    h["X-WebKit-CSP"] = val
    h
  end
  
  def permit_headers(h)    
    h['Access-Control-Allow-Origin'] = '*' 
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