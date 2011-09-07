module FaradayStack
  class ResponseXML < ResponseMiddleware
    dependency do
      require 'nokogiri'
      Nokogiri::XML
    end
    
    define_parser do |body|
      NokogiriHash.new body
    end
  end
end