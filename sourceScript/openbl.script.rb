#!/usr/bin/env ruby
require 'curb'
require 'nokogiri'

puts "[openblScript]: Start"
puts "[openblScript]: Retrive the data"
@inputScriptXmlPath = gets.chomp
# Create the xml structure for output file
puts "[openblScript]: Create the xml"
builder = Nokogiri::XML::Builder.new do |xml|
  xml << '<!--Updates from openbl list-->'
  xml.Items {
    # Retrive the update data
    curl = Curl::Easy.new('http://www.openbl.org/lists/base_1days.txt')
        curl.proxy_url = ENV['http_proxy']
	curl.max_redirects = 3 
	curl.ssl_verify_peer = false
	curl.perform
    data = curl.body_str.split("\n")
    data.each do |line|
      # Consider only the valid IP address
      if line =~ /(?:^|\s)([a-z]{3,6}(?=:\/\/))?(:\/\/)?((?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.(?:25[0-5]|2[0-4]\d|[01]?\d\d?))(?::(\d{2,5}))?(?:\s|$)/
        # Save the item in the xmlFile
        xml.Item {
          xml.Type "Ip"
          xml.Value line
        }
      end
    end
  }
end
file = File.new("#{@inputScriptXmlPath}openbl.xml", "wb")
file.write builder.to_xml
file.close
puts "[openblScript]: End"
