#!/usr/bin/env ruby
require 'curb'
require 'nokogiri'
require 'open-uri'
require 'uri'

puts "[supportcleanmxlistScript]: Start"
puts "[supportcleanmxlistScript]: Retrive the data"
@inputScriptXmlPath = gets.chomp
# Create the xml structure for output file
puts "[supportcleanmxlistScript]: Create the xml"
builder = Nokogiri::XML::Builder.new do |xml|
  xml << '<!--Updates from supportcleanmxlist list-->'
  xml.Items {
    # Retrive the update data
	curl = Curl::Easy.new('http://support.clean-mx.de/clean-mx/xmlviruses.php?')
        curl.proxy_url = ENV['http_proxy']
	curl.max_redirects = 3 
	curl.ssl_verify_peer = false
	curl.perform
	doc = Nokogiri::XML(curl.body_str.to_s)
	puts doc
    doc.css("md5").each do |link|
	  title = link.content
	  title.each do |line|
		# Consider only valid hashes
        if line =~ /^[0-9a-f]{32}$/
          # Save the item in the xmlFile
          xml.Item {
            xml.Type "Hash"
            xml.Value line
            xml.HashAlgorithm "MD5"
          }
        end
	  end
	end
  }
end

file = File.new("#{@inputScriptXmlPath}supportcleanmxlist.xml", "wb")
file.write builder.to_xml
file.close
puts "[supportcleanmxlistScript]: End"



