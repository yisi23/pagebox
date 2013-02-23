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

  def default_headers
    val = 'Sandbox allow-scripts allow-top-navigation allow-forms allow-popups'

    {
      "X-XSS-Protection" => '0;',
      "Content-Security-Policy" => val,
      "X-WebKit-CSP" => val
    }
  end
  def permit_headers
    default_headers.merge({
      'Access-Control-Allow-Origin' => '*', 
      'Access-Control-Allow-Headers' => 'Cookie,Origin-Map,X-CSRF-Token,Content-Type'
    })
  end
  
end