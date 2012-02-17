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
        @counter = {}
      end

      def counter(prefix,suffix)
        @counter[prefix + '////' + suffix]
      end

      def set_counter(prefix,suffix,val)
        @counter[prefix + '////' + suffix] = val
      end
      
      def generate_key(param = {})
        while (true)
          prefix = param[:prefix] || ''
          suffix = param[:suffix] || ''
          count = [ param[:start] || 0, counter(prefix,suffix) || 0].max
          k = prefix + count.to_s + suffix
          return k if @pool[k].nil?
          count += 1
        end
        set_counter(prefix,suffix, count)
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
          @attributes = attr_to_hash(@xml.root.attributes)
          @metadata = Metadata.parse(@xml.at_xpath("//#{prefix(OPF_NS)}:metadata"), @attributes['version'], @id_pool)
          @manifest = Manifest.parse(@xml.at_xpath("//#{prefix(OPF_NS)}:manifest"), @attributes['version'], @id_pool)
          @spine = Spine.parse(@xml.at_xpath("//#{prefix(OPF_NS)}:spine"), @attributes['version'], @id_pool)
        }
      }
    end
    
    def initialize(path, attributes={})
      @namespaces = {'xmlns' => OPF_NS }
      @attributes = attributes
      @attributes['version'] ||= '3.0'
      @id_pool = IDPool.new
      yield self if block_given?
    end

    def [](x)
      @attributes[x]
    end

    def []=(k,v)
      @attributes[k] = v
    end
  end
end
