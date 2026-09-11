#!/usr/bin/env ruby
require 'curb'
require 'nokogiri'

puts "[nothinkScript]: Start"
puts "[nothinkScript]: Retrive the data"

@inputScriptXmlPath = gets.chomp
# Create the xml structure for output file
puts "[nothinkScript]: Create the xml"
builder = Nokogiri::XML::Builder.new do |xml|
  xml << '<!--Updates from nothink list-->'
  xml.Items {
    # Retrive the update data
    curl = Curl::Easy.new('http://www.nothink.org/honeypots/malware_md5_list.txt')
        curl.proxy_url = ENV['http_proxy']
	curl.max_redirects = 3 
	curl.ssl_verify_peer = false
	curl.perform
    data = curl.body_str.split("\n")
    data.each do |line|
      # Consider only valid hashes
      lineValue = line.split(";")
      if lineValue[1] =~ /^[0-9a-f]{32}$/
        # Save the item in the xmlFile
        xml.Item {
          xml.Type "Hash"
          xml.Value lineValue[1]
          xml.HashAlgorithm "MD5"
		  xml.Date lineValue[3]
        }
      end
    end
  }
end
file = File.new("#{@inputScriptXmlPath}nothink.xml", "wb")
file.write builder.to_xml
file.close
puts "[nothinkScript]: End"
