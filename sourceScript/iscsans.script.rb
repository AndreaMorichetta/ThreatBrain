#!/usr/bin/env ruby
require 'curb'
require 'nokogiri'

puts "[iscscanScript]: Start"
puts "[iscscanScript]: Retrive the data"
@inputScriptXmlPath = gets.chomp
# Create the xml structure for output file
puts "[iscscanScript]: Create the xml"
builder = Nokogiri::XML::Builder.new do |xml|
  xml << '<!--Updates from iscscan list-->'
  xml.Items {
    # Retrive the update data
    curl = Curl::Easy.new('https://isc.sans.edu/feeds/suspiciousdomains_High.txt')
        curl.proxy_url = ENV['http_proxy']
	curl.max_redirects = 3 
    curl.ssl_verify_peer = false
	curl.perform
	data = curl.body_str.split(" ")
    data.each do |line|
      # Consider only valid domains
      if line =~ /(\A\z)|(\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?)?\z)/
        # Save the item in the xmlFile
        xml.Item {
          xml.Type "Domain"
          xml.Value line
        }
      end
    end
  }
end
file = File.new("#{@inputScriptXmlPath}iscscan.xml", "wb")
file.write builder.to_xml
file.close
puts "[iscscanScript]: End"
