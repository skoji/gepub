require 'rubygems'
require 'nokogiri'

module GEPUB
  # Holds data in opf file.
  class PackageData
    include XMLUtil
    attr_accessor :path

    class IDPool
      def initialize
        @pool = {}
      end

      def generate_key(param = {})
        while (true)
          prefix = param[:prefix] || ''
          suffix = param[:suffix] || ''
          start = param[:start] || 0
          k = prefix + start.to_s + suffix
          return k if @pool[k].nil?
          start += 1
        end
      end
      
      def [](k)
        @pool[k]
      end
      def []=(k,v)
        @pool[k] = v
      end
    end
    
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
