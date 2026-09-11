#!/usr/bin/env ruby
require 'curb'
require 'nokogiri'
require 'uri'
require 'cgi'

puts "[cybercrimeScript]: Start"
puts "[cybercrimeScript]: Retrive the data"
@inputScriptXmlPath = gets.chomp
# Create the xml structure for output file
puts "[cybercrimeScript]: Create the xml"
builder = Nokogiri::XML::Builder.new do |xml|
  xml << '<!--Updates from cybercrime list-->'
  xml.Items {
    # Retrive the update data
    curl = Curl::Easy.new('http://cybercrime-tracker.net/all.php')
        curl.proxy_url = ENV['http_proxy']
	curl.max_redirects = 3 
	curl.ssl_verify_peer = false
	curl.perform
    data = curl.body_str.to_s
	data = data.split("<br />")
    data.each do |line|
      # Consider only the valid Urls 
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
file = File.new("#{@inputScriptXmlPath}cybercrime.xml", "wb")
file.write builder.to_xml
file.close
puts "[cybercrimeScript]: End"
