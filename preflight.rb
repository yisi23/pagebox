class Preflight < Pagebox::Preflight

  def permit?(req, pagebox)
  	puts "permit? #{req.path} for #{pagebox.data}"

    case req.path
    when /\A\/payments/
      # serious business.
      pagebox.permit? :payments
    else
      pagebox.permit? :basic
    end
  end

  def default_headers(h)
    #allow-same-origin
    val = 'Sandbox allow-scripts  allow-top-navigation allow-forms allow-popups'

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


  
end