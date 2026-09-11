#!/usr/bin/env ruby
require 'curb'
require 'nokogiri'
require 'open-uri'
require 'uri'

puts "[malc0deScript]: Start"
puts "[malc0deScript]: Retrive the data"
@inputScriptXmlPath = gets.chomp
# Create the xml structure for output file
puts "[malc0deScript]: Create the xml"
builder = Nokogiri::XML::Builder.new do |xml|
  xml << '<!--Updates from malc0de list-->'
  xml.Items {
    # Retrive the update data
    curl = Curl::Easy.new('http://malc0de.com/rss/')
    curl.proxy_url = ENV['http_proxy']
    curl.max_redirects = 3 
    curl.ssl_verify_peer = false
    curl.perform
    doc = Nokogiri::XML(curl.body_str.to_s)	
    doc.css("item").map {
      |node| 
      node.children.css("title").map { 
        |title| 
        @tagTitle = title.content 
      }
      node.children.css("description").map { 
        |description| 
        @tagDescription = description.content 
      }
      dataTitle = @tagTitle.to_s.split("\n")
      dataDescription = @tagDescription.to_s.split(",")	  
      dataTitle.each do |line|
        # Consider only valid domains
        if line =~ /(\A\z)|(\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?)?\z)/
          # Save the item in the xmlFile
          xml.Item {
            xml.Type "Domain"
            xml.Value line
          }
        end
      end
      dataDescription.each do |line|
        if line.include? 'IP'
          line = line.gsub(/\s+/, "").strip
          line = line.gsub "IPAddress:" , ""
          # Consider only valid Ip
          if line =~ /(?:^|\s)([a-z]{3,6}(?=:\/\/))?(:\/\/)?((?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.(?:25[0-5]|2[0-4]\d|[01]?\d\d?))(?::(\d{2,5}))?(?:\s|$)/
            # Save the item in the xmlFile
            xml.Item {
              xml.Type "Ip"
              xml.Value line
            }
          end	
        end
        if line.include? 'URL'
          line = line.gsub(/\s+/, "").strip.gsub "URL:" , ""
          # Consider only valid Urls 
          line2 = URI.parse(line) rescue line2 = nil
          if !line2.nil?
            # Save the item in the xmlFile
            xml.Item {
              xml.Type "Url"
              xml.Value line
            }
          end
        end
        if line.include? 'MD5'
          line = line.gsub(/\s+/, "").strip.gsub "MD5:" , ""
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
  }
end

file = File.new("#{@inputScriptXmlPath}malc0de.xml", "wb")
file.write builder.to_xml
file.close
puts "[malc0deScript]: End"

