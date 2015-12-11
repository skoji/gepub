require 'coveralls'
Coveralls.wear!

require "stringio"

begin
  require 'rspec'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rspec'
  require 'spec'
end

RSpec.configure do |config|
  # Use color in STDOUT
  config.color = true
  # Use color not only in STDOUT but also in pagers and files
  config.tty = true
  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval "$#{stream} = #{stream.upcase}"
    end
    result
  end

  def epubcheck(epubname)
    jar = File.join(File.dirname(__FILE__), 'fixtures/epubcheck-4.0.1/epubcheck.jar')    
    stdout = capture(:stdout) do 
      puts %x(java -Duser.language=en -jar #{jar} #{epubname})
    end
    expect(stdout).to include("No errors or warnings detected.")
  end
  
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
