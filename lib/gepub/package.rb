require 'rubygems'
require 'nokogiri'

module GEPUB
  # Holds data in opf file.
  class Package
    include XMLUtil
    attr_accessor :path, :metadata, :manifest, :spine, :epub_backward_compat, :contents_prefix

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
            param.delete(:without_count)
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
      Package.new(path) {
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

    def initialize(path='OEBPS/package.opf', attributes={})
      @path = path
      if File.extname(@path) != '.opf'
        if @path.size > 0
          @path = [path,'package.opf'].join('/')
        end
      end
      @contents_prefix = File.dirname(@path).sub(/^\.$/,'')
      @contents_prefix = @contents_prefix + '/' if @contents_prefix.size > 0
      @namespaces = {'xmlns' => OPF_NS }
      @attributes = attributes
      @attributes['version'] ||= '3.0'
      @id_pool = IDPool.new
      @metadata = Metadata.new(version)
      @manifest = Manifest.new(version)
      @spine = Spine.new(version)
      @epub_backward_compat = true
      yield self if block_given?
    end

    ['unique-identifier', 'xml:lang', 'dir', 'prefix', 'id'].each {
      |name|
      methodbase = name.gsub('-','_').sub('xml:lang', 'lang')
      define_method(methodbase + '=') { |val| @attributes[name] =  val }
      define_method('set_' + methodbase) { |val| @attributes[name] = val }        
      define_method(methodbase) { @attributes[name] }
    }

    def [](x)
      @attributes[x]
    end

    def []=(k,v)
      @attributes[k] = v
    end


    def identifier
      @metadata.identifier_by_id(unique_identifier)
    end
    
    def identifier=(identifier)
      set_main_id(identifier, nil, 'URL')
    end
    
    def set_main_id(identifier, id = nil, type = nil)
      set_unique_identifier(id || @id_pool.generate_key(:prefix => 'BookId', :without_count => true))
      @metadata.add_identifier identifier, unique_identifier, type
    end

    def add_item(href, io_or_filename = nil, id = nil, attributes = {})
      item = @manifest.add_item(id, href, nil, attributes)
      item.add_content(io_or_filename) unless io_or_filename.nil?
      @spine.push(item) if @ordered
      yield item if block_given?
      item
    end

    def ordered
      raise 'need block.' if !block_given?
      @ordered = true
      yield
      @ordered = nil
    end

    def add_ordered_item(href, io_or_filename = nil, id = nil, attributes = {})
      raise 'do not call add_ordered_item within ordered block.' if @ordered
      item = add_item(href, io_or_filename, id, attributes)
      @spine.push(item)
      
      item
    end

    def spine_items
      spine.itemref_list.map {
        |itemref|
        @manifest.item_list[itemref.idref]
      }
    end

    def items
      @manifest.item_list
    end
    
    def method_missing(name, *args)
      return @manifest.send(name.to_sym, *args) if [:item_by_href].member? name
      Metadata::CONTENT_NODE_LIST.each {
        |x|
        case name.to_s
        when x, "#{x}_list", "set_#{x}", "#{x}=", "add_#{x}"
          return @metadata.send(name, *args)
        end
      }
      super
    end

    def author=(val)
      warn 'author= is deprecated. please use #creator'
      @metadata.creator= val
    end

    def author
      warn '#author is deprecated. please use #creator'
      @metadata.creator
    end      

    def specify_cover_image(item)
      warn 'specify_cover_image is deprecated. please use Item#cover_image'
      item.cover_image
    end

    def locale=(val)
      warn 'locale= is deprecated. please use #language='
      @metadata.language = val
    end

    def locale 
      warn '#locale is deprecated. please use #language'
      @metadata.language
    end

    def version
      @attributes['version']
    end

    def set_version(val)
      @attributes['version'] = val
      @metadata.opf_version = val
      @manifest.opf_version = val
      @spine.opf_version = val
    end

    def version=(val)
      set_version(val)
    end
    
    def epub_version=(val)
      warn 'epub_version= is deprecated. please use #version='
      @attributes['version'] = val
    end

    def epub_version
      warn 'epub_version is deprecated. please use #version'
      version
    end

    def opf_xml
      if version.to_f < 3.0 || @epub_backward_compat
        spine.toc  ||= 'ncx'
        if @metadata.oldstyle_meta.select {
          |meta|
          meta['name'] == 'cover'
          }.length == 0
          
          @manifest.item_list.each {
            |k, item|
            if item.properties && item.properties.member?('cover-image')
              @metadata.add_oldstyle_meta(nil, 'name' => 'cover', 'content' => item.id)
            end
          }
        end
      end
      builder = Nokogiri::XML::Builder.new {
        |xml|
        xml.package(@namespaces.merge(@attributes)) {
          @metadata.to_xml(xml)
          @manifest.to_xml(xml)
          @spine.to_xml(xml)
        }
      }
      builder.to_xml(:encoding => 'utf-8')
    end


  end
end
