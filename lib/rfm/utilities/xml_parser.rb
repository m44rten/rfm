module Rfm
	module XmlParser
		require 'rubygems'
		require 'active_support/xml_mini'
		
		extend self
		
		attr_reader :backend
		
		def select_backend(name)
			@backend = case name
			when :jdom
				'JDOM'
			when :libxml
				'LibXML'
			when :libxmlsax
				'LibXMLSAX'
			when :nokogiri
				'Nokogiri'
			when :nokogirisax
				'NokogiriSAX'
			when :rexml
				'REXML'
			when :hpricot
				require File.join(File.dirname(__FILE__), '../xml_mini/hpricot.rb')
				ActiveSupport::XmlMini_Hpricot
			end
		end
		
		def decide_backend
			begin
				require 'jdom'
				select_backend :jdom
			rescue LoadError
				require 'libxml'
				select_backend :libxml
			rescue LoadError
				require 'nokogiri'
				select_backend :nokogirisax
			rescue LoadError
				require 'hpricot'
				select_backend :hpricot
			rescue LoadError
				select_backend :rexml
			end
			ActiveSupport::XmlMini.backend = @backend
		end
		
		decide_backend

		def new(string_or_file, opts={})
			string_or_file.gsub!(/xmlns=\"[^\"]*\"/,'') if (string_or_file.class == String and opts[:namespace] == false)
			unless opts[:backend]
				ActiveSupport::XmlMini.parse(string_or_file)
			else
				ActiveSupport::XmlMini.with_backend(select_backend(opts[:backend])) {ActiveSupport::XmlMini.parse(string_or_file)}
			end
		end
		
		class ::Hash
			def ary
				[self]
			end
		end
		
		class ::Array
			def ary
				self
			end
		end	 

	end
end



### Old Code for Other Parsers ###

#		begin
# 		require 'nokogiri'
# 		puts "Using Nokogiri"
# 		@parser = proc{|*args| Nokogiri.XML(*args)}
# 	rescue LoadError
# 		require 'ox'
# 		@parser = proc{|*args| }
# 	rescue LoadError
# 		require 'libxml'
# 		@parser = proc{|*args| LibXML::XML::Parser.string(*args).parse}
# 	rescue LoadError
# 		require 'hpricot'
# 		Hpricot::Doc.class_eval{alias_method :xpath, :search}
# 		Hpricot::Elements.class_eval{alias_method :xpath, :search}
# 		@parser = proc{|*args| Hpricot.XML(*args)}
# 	rescue LoadError
# 		require 'rexml/document'
# 		puts "Using REXML"
# 		REXML::Element.class_eval{def xpath(str); self.elements[str]; end}
# 		@parser = proc{|*args| REXML::Document.new(*args)}
# 	rescue LoadError
# 		require 'multi_xml'
# 		@parser = proc{|*args| MultiXml.parser = :ox; MultiXml.parse(*args)}
# 	rescue LoadError
# 		require 'active_support/xml_mini'
# 		@parser = proc{|*args| ActiveSupport::XmlMini.backend = 'LibXMLSAX'; ActiveSupport::XmlMini.parse(*args)}
#		end
# 
# 	def self.new(*args)
# 		opts = args.pop if args.last.is_a? Hash
# 		args[0].gsub!(/xmlns=\"[^\"]*\"/,'') if (args[0].class == String and opts[:namespace] == false)
# 		@parser.call(args)
# 	end