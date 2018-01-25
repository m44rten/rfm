module Rfm
  # Add load path for library usage without rubygems.
  MODEL_PATH = File.expand_path(File.dirname(__FILE__))
  $LOAD_PATH.unshift(PATH) unless $LOAD_PATH.include?(PATH)
end

require 'rfm/model'