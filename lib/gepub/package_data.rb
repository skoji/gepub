require 'rubygems'
require 'nokogiri'

module GEPUB
  # Holds data in opf file.
  class PackageData
    attr_accessor :path
    def self.parse_opf(opf, path)
      PackageData.new(path) {
        |package|
        package.instance_eval {
          @path = path
          @xml = Nokogiri::XML::Document.parse(opf)
          @namespaces = @xml.root.namespaces
          @xml.root.keys.each {
            |k|
            @attr[k] = @xml.root[k]
          }
        }
      }
    end
    
    def initialize(path, attr={})
      @namespaces = {'xmlns' => 'http://www.idpf.org/2007/opf'}
      @attr = attr
      yield self if block_given?
    end

    def [](x)
      @attr[x]
    end

    def []=(k,v)
      @attr[k] = v
    end
  end
end
