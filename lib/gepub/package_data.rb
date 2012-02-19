require 'rubygems'
require 'nokogiri'

module GEPUB
  # Holds data in opf file.
  class PackageData
    include XMLUtil
    attr_accessor :path, :metadata, :manifest, :spine

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
          count = [ param[:start] || 1, counter(prefix,suffix) || 1].max
          if param[:without_count]
            k = prefix + suffix
            count -= 1
            param[:without_count] = nil
          else
            k = prefix + count.to_s + suffix
          end
          if @pool[k].nil?
            set_counter(prefix,suffix, count + 1)
            return k
          end
          count += 1
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
          @attributes = attr_to_hash(@xml.root.attributes)
          @metadata = Metadata.parse(@xml.at_xpath("//#{ns_prefix(OPF_NS)}:metadata"), @attributes['version'], @id_pool)
          @manifest = Manifest.parse(@xml.at_xpath("//#{ns_prefix(OPF_NS)}:manifest"), @attributes['version'], @id_pool)
          @spine = Spine.parse(@xml.at_xpath("//#{ns_prefix(OPF_NS)}:spine"), @attributes['version'], @id_pool)
        }
      }
    end
    
    def initialize(path, attributes={})
      @namespaces = {'xmlns' => OPF_NS }
      @attributes = attributes
      @attributes['version'] ||= '3.0'
      @id_pool = IDPool.new
      @metadata = Metadata.new(version)
      @manifest = Manifest.new(version)
      @spine = Spine.new(version)
      yield self if block_given?
    end

    ['version', 'unique-identifier', 'xml:lang', 'dir', 'prefix', 'id'].each {
      |name|
      methodbase = name.gsub('-','_').sub('xml:lang', 'lang')
      define_method(methodbase + '=') { |val| @attributs[name] =  val }
      define_method('set_' + methodbase) { |val| @attributes[name] = val }        
      define_method(methodbase) { @attributes[name] }
    }

    def [](x)
      @attributes[x]
    end

    def []=(k,v)
      @attributes[k] = v
    end

    def set_main_id(identifier, id = nil, type = nil)
      unique_identifier = id || id_pool.generate_key(:prefix => 'BookId', :without_count => true)
      @metadata.set_identifier identifier, unique_identifier, type
    end
    
    def specify_cover(item)
      # ... not smart. should create old-meta on generating xml
      @metadata.add_oldstyle_meta(nil, { 'name' => 'cover', 'content' => item.id })
      item.add_properties 'cover-image'
    end

    def add_item(href, io = nil, id = nil, attributes = {})
      id ||= @id_pool.generate_key(:prefix=>'item', :suffix=>'_'+ File.basename(href,'.*'), :without_count => true)
      item = @manifest.add_item(id, href, nil, attributes)
      item.add_content(io) unless io.nil?
      spine.push(item) if @ordered
      yield item if block_given?
      item
    end

    def ordered
      raise 'call with block.' if !block_given?
      @ordered = true
      yield
      @ordered = nil
    end

    def add_ordered_item(href, io = nil, id = nil, attributes = {})
      raise 'do not call add_ordered_item within ordered block.' if @ordered
      item = add_item(href, io, id, attributes)
      spine.push(item)
      item
    end

    def to_xml
      builder = Nokogiri::XML::Builder.new {
        |xml|
        xml.package(@namespaces.merge(@attributes)) {
          @metadata.to_xml(xml)
          @manifest.to_xml(xml)
          @spine.to_xml(xml)
        }
      }
      builder.to_xml
    end
  end
end
