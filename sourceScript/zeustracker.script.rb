#!/usr/bin/env ruby
require 'curb'
require 'nokogiri'
require 'uri'

puts "[zeustrackerScript]: Start"
puts "[zeustrackerScript]: Retrive the data"
@inputScriptXmlPath = gets.chomp
# Create the xml structure for output file
puts "[zeustrackerScript]: Create the xml"
builder = Nokogiri::XML::Builder.new do |xml|
  xml << '<!--Updates from zeustracker list-->'
  xml.Items {
    # Retrive the update data
	curl = Curl::Easy.new
	["https://zeustracker.abuse.ch/rss.php", 
	"https://zeustracker.abuse.ch/monitor.php?urlfeed=binaries"].map do |url|
      curl.url = url
          curl.proxy_url = ENV['http_proxy']
	  curl.max_redirects = 3 
	  curl.ssl_verify_peer = false
      curl.perform
	  if curl.url == "https://zeustracker.abuse.ch/rss.php"
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
		  node.children.css("link").map { 
            |link| 
            @tagLink = link.content 
          }
	      node.children.css("guid").map { 
            |hash| 
            @tagHash = hash.content 
          }
	      dataTitle = @tagTitle.to_s.split(" ")
	      dataDescription = @tagDescription.to_s.split(",")
	      dataHash = @tagHash.to_s.split("\n")
	      dataTitle.each do |line|
		    #Consider only valid domains
	        if line =~ /(\A\z)|(\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?)?\z)/
	          #Save the item in the xmlFile
              xml.Item {
                xml.Type "Domain"
                xml.Value line
			    if !dataTitle.nil?
				  xml.Date dataTitle[1].gsub(/[()]/ , "(" => "" , ")" => "")
			    end
              }
		    end
	      end
	      dataDescription.each do |line|
	        if line.include? 'IP'
		      line = line.gsub(/\s+/, "").strip.gsub "IPaddress:" , ""
	          #Consider only valid Ip
		      if line =~ /(?:^|\s)([a-z]{3,6}(?=:\/\/))?(:\/\/)?((?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.(?:25[0-5]|2[0-4]\d|[01]?\d\d?))(?::(\d{2,5}))?(?:\s|$)/
                #Save the item in the xmlFile
                xml.Item {
                  xml.Type "Ip"
                  xml.Value line
			      if !dataTitle.nil?
				    xml.Date dataTitle[1].gsub(/[_()]/ , "(" => "" , ")" => "")
			      end
				  comment = dataDescription[4].gsub("level:", "").strip
				  puts comment
				  if comment == "5"
				    xml.Comment "Hosted on a FastFlux botnet"
				  elsif comment == "4"
				    xml.Comment "Unknown"
				  elsif comment == "3"
				    xml.Comment "Free hosting service"
				  elsif comment == "2"
				    xml.Comment "Hacked webserver"
				  elsif comment == "1"
				    xml.Comment "Bulletproof hosted"
				  end
                }
		      end	
            end	
	      end	
	    }
	  end
	  if curl.url == "https://zeustracker.abuse.ch/monitor.php?urlfeed=binaries"
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
		  dataTitle = @tagTitle.to_s.split(" ")
	      dataDescription = @tagDescription.to_s.split(",")
	      dataDescription.each do |line|
	        if line.include? 'URL'
			  #Consider only valid Urls
		      line = line.gsub(/\s+/, "").gsub("URL:" , "")
	          line2 = URI.parse(line) rescue line2 = nil
                if !line2.nil?
                #Save the item in the xmlFile
                  xml.Item {
                    xml.Type "Url"
                    xml.Value line
					if !dataTitle.nil?
				      xml.Date dataTitle[1].gsub(/[()]/ , "(" => "" , ")" => "")
			        end
                  }
                end			
            end
			if line.include? 'MD5'
		      #Consider only valid hashes
			  line = line.gsub(/\s+/, "").gsub("MD5hash:" , "").strip
              if line =~ /^[0-9a-f]{32}$/
                #Save the item in the xmlFile
                xml.Item {
				  if !line.nil?
                    xml.Type "Hash"
                    xml.Value line
                    xml.HashAlgorithm "MD5"
					if !dataTitle.nil?
				      xml.Date dataTitle[1].gsub(/[()]/ , "(" => "" , ")" => "")
			        end					
				  end	
                }
              end 			
	        end	
		  end	
	    }
	  end	  
    end
  }
end
file = File.new("#{@inputScriptXmlPath}zeustracker.xml", "wb")
file.write builder.to_xml
file.close
puts "[zeustrackerScript]: End"
