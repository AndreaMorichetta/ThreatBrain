#!/usr/bin/env ruby
require 'curb'
require 'nokogiri'
require 'uri'

puts "[vxvaultScript]: Start"
puts "[vxvaultScript]: Retrive the data"
@inputScriptXmlPath = gets.chomp
# Create the xml structure for output file
puts "[vxvaultScript]: Create the xml"
builder = Nokogiri::XML::Builder.new do |xml|
  xml << '<!--Updates from vxvault list-->'
  xml.Items {
    # Retrive the update data
    curl = Curl::Easy.new('http://vxvault.siri-urz.net/URL_List.php')
	curl.proxy_url = ENV['http_proxy']
	curl.max_redirects = 3 
	curl.ssl_verify_peer = false
	curl.perform
    data = curl.body_str.split("\n")
    data.each do |line|
      # Consider only valid Urls
	  line = line.strip
	  line2 = URI.parse(line) rescue line2 = nil
      if !line2.nil?
        # Save the item in the xmlFile
        xml.Item {
          xml.Type "Url"
          xml.Value line
        }
      end
    end
  }
end
file = File.new("#{@inputScriptXmlPath}vxvault.xml", "wb")
file.write builder.to_xml
file.close
puts "[vxvaultScript]: End"
