require 'epubcheck/ruby/cli'
require 'simplecov'
require "simplecov-json"
SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter
])
SimpleCov.start do
  enable_coverage :branch
end  

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
    jar = Epubcheck::Ruby::CLI::JAR_FILE
    stdout = capture(:stdout) do 
      puts %x(java -Duser.language=en -jar #{jar} #{epubname} 2>&1)
    end
    expect(stdout).to include("No errors or warnings detected.")
  end

  config.before(:all) do
    @fixtures_directory = Pathname(__FILE__).dirname / "fixtures"
  end
  
  config.around(:example, :uses_temporary_directory) do |example|
    @temporary_directory = Pathname(Dir.mktmpdir("gepub_spec"))    
    example.run
  ensure
    @temporary_directory.rmtree
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
