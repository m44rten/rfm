#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
# This gemspec has been crafted by hand - do not overwrite with Jeweler!
# See http://yehudakatz.com/2010/12/16/clarifying-the-roles-of-the-gemspec-and-gemfile/
# See http://yehudakatz.com/2010/04/02/using-gemspecs-as-intended/
# for more information on bundler and gems.

require 'date'

Gem::Specification.new do |s|
  s.name = "rfm-core"
  s.summary = "Ruby Filemaker adapter core functionality"
  s.version = "0.0.0" #File.read('./lib/rfm/VERSION') #Rfm::VERSION

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bill Richardson"]
  s.date = Date.today.to_s
  s.description = "Rfm core functionality."
  s.email = "http://groups.google.com/group/rfmcommunity"
  s.homepage = "https://github.com/ginjo/rfm"
  
  s.require_paths = ["lib"]
  s.files = Dir['lib/**/*.rb', 'lib/**/VERSION',  '.yardopts']
  
  s.rdoc_options = ["--line-numbers", "--main", "README.md"]
  s.extra_rdoc_files = [
    #"LICENSE",
    #"README.md",
    #"lib/rfm/VERSION"
  ]

  #s.add_dependency('saxchange')

  #   s.add_development_dependency(%q<rake>, [">= 0"])
  #   s.add_development_dependency(%q<rdoc>, [">= 0"])
  #   s.add_development_dependency(%q<rspec>, [">= 2"])
  #   s.add_development_dependency(%q<minitest>, [">= 0"])
  #   s.add_development_dependency(%q<diff-lcs>, [">= 0"])
  #   s.add_development_dependency(%q<yard>, [">= 0"])
  #   s.add_development_dependency(%q<redcarpet>, [">= 0"])
  #   s.add_development_dependency(%q<ruby-prof>, [">= 0"])
  #   s.add_development_dependency(%q<libxml-ruby>, [">= 0"]) unless RUBY_PLATFORM == 'java'
  #   s.add_development_dependency(%q<ox>, [">= 0"])
  #   s.add_development_dependency(%q<nokogiri>, [">= 0"])
  
end # Gem::Specification.new
