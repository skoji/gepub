require 'rubygems'
require 'nokogiri'

module GEPUB
  # Holds data in opf file.
  class PackageData
    include XMLUtil
    attr_accessor :path

    # parse OPF data. opf should be io or string object.
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
          @metadata = Metadata.parse(@xml.xpath("//#{prefix(OPF_NS)}:metadata")[0], @attr['version'])
        }
      }
    end
    
    def initialize(path, attr={})
      @namespaces = {'xmlns' => OPF_NS }
      @attr = attr
      @attr['version'] ||= '3.0'
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
