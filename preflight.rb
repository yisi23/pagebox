#require 'rack/request'

DEFAULT_HEADERS = {'Access-Control-Allow-Origin' => '*', 
                  'Access-Control-Allow-Headers' => 'Cookie,Origin-Map,X-CSRF-Token,Content-Type',
                  "X-XSS-Protection" => '0;'}

val = 'Sandbox allow-scripts allow-top-navigation allow-forms'
DEFAULT_HEADERS["Content-Security-Policy"]=val
DEFAULT_HEADERS["X-WebKit-CSP"]=val

class Preflight < Pagebox::Preflight

  def allow?(req, pagebox)
    true

  end
  
end