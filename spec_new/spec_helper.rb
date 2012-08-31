begin
  require 'rspec'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rspec'
  require 'spec'
end

RSpec.configure do |config|
  # Use color in STDOUT
  config.color_enabled = true
  # Use color not only in STDOUT but also in pagers and files
  config.tty = true
  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate
end

require 'rspec/core/formatters/base_text_formatter'
module RSpec
  module Core
    module Formatters
      class DocumentationFormatter < BaseTextFormatter
			  # def green(text); color(text, "\e[42m") end
			  def red(text); color(text, "\e[41m") end
			  # def magenta(text); color(text, "\e[45m") end
			end
		end
	end
end
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'gepub'
