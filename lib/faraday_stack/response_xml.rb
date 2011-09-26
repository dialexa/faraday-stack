module FaradayStack
  class ResponseXML < ResponseMiddleware
    dependency do
      require 'active_support'
    end
    
    define_parser do |body|
      Hash.from_xml body
    end
  end
end