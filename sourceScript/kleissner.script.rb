#!/usr/bin/env ruby
require 'curb'
require 'nokogiri'

puts "[kleissnerScript]: Start"
puts "[kleissnerScript]: Retrive the data"
@inputScriptXmlPath = gets.chomp
# Create the xml structure for output file
puts "[kleissnerScript]: Create the xml"
builder = Nokogiri::XML::Builder.new do |xml|
  xml << '<!--Updates from kleissner list-->'
  xml.Items {
    # Retrive the update data
    curl = Curl::Easy.new('http://www.kleissner.org/text/ZeuSGameover_Domains.txt')
        curl.proxy_url = ENV['http_proxy']
	curl.max_redirects = 3 
	curl.ssl_verify_peer = false
	curl.perform
    data = curl.body_str.split("\n")
	data.each do |line|
	  line2 = line.split(",")
	  line3 = line2[1].to_s.gsub('\r','').strip
      # Consider only valid domains
      if line3 =~ /(\A\z)|(\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?)?\z)/
        # Save the item in the xmlFile
        xml.Item {
          xml.Type "Domain"
          xml.Value line3
        }
      end
    end
  }
end
file = File.new("#{@inputScriptXmlPath}kleissner.xml", "wb")
file.write builder.to_xml
file.close
puts "[kleissnerScript]: End"
