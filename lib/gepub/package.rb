require 'rubygems'
require 'nokogiri'
require 'forwardable'

module GEPUB
  # Holds data in opf file.
  class Package
    include XMLUtil, DSLUtil
    include InspectMixin

    extend Forwardable
    attr_accessor :path, :metadata, :manifest, :spine, :bindings, :epub_backward_compat, :contents_prefix, :prefixes 
    def_delegators :@manifest, :item_by_href
    def_delegators :@metadata, *Metadata::CONTENT_NODE_LIST.map {
      |x|
      if x == "identifier"
        ["#{x}_list", "set_#{x}", "add_#{x}"]
      else
        ["#{x}", "#{x}_list", "set_#{x}", "#{x}=", "add_#{x}"]
      end
    }.flatten
    def_delegators :@metadata, :set_lastmodified
    def_delegators :@metadata, :lastmodified
    def_delegators :@metadata, :lastmodified=
    def_delegators :@metadata, :modified_now
    def_delegators :@metadata, :rendition_layout
    def_delegators :@metadata, :rendition_layout=
    def_delegators :@metadata, :rendition_orientation
    def_delegators :@metadata, :rendition_orientation=
    def_delegators :@metadata, :rendition_spread
    def_delegators :@metadata, :rendition_spread=
    def_delegators :@metadata, :ibooks_version
    def_delegators :@metadata, :ibooks_version=
    def_delegators :@metadata, :ibooks_scroll_axis
    def_delegators :@metadata, :ibooks_scroll_axis=

    def_delegators :@spine, :page_progression_direction=
    def_delegators :@spine, :page_progression_direction


    class IDPool
      # @rbs () -> void
      def initialize
        @pool = {}
        @counter = {}
      end

      # @rbs (String, String) -> Integer?
      def counter(prefix,suffix)
        @counter[prefix + '////' + suffix]
      end

      # @rbs (String, String, Integer) -> void
      def set_counter(prefix,suffix,val)
        @counter[prefix + '////' + suffix] = val
      end
      
      # @rbs (?Hash[untyped, untyped]) -> String
      def generate_key(param = {})
        prefix = param[:prefix] || ''
        suffix = param[:suffix] || ''
        count = [ param[:start] || 1, counter(prefix,suffix) || 1].max
        while (true)
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
      
      # @rbs (String?) -> bool?
      def [](k)
        @pool[k]
      end
      # @rbs (String?, bool?) -> bool?
      def []=(k,v)
        @pool[k] = v
      end
    end

    # @rbs (String?) -> Hash[untyped, untyped]
    def parse_prefixes(prefix)
      return {} if prefix.nil?
      m = prefix.scan(/([\S]+): +(\S+)[\s]*/)
      Hash[*m.flatten]
    end
    
    # parse OPF data. opf should be io or string object.
    # @rbs (File | String, String) -> GEPUB::Package
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
          @bindings = Bindings.parse(@xml.at_xpath("//#{ns_prefix(OPF_NS)}:bindings"))
          @prefixes = parse_prefixes(@attributes['prefix'])
        }
      }
    end

    # @rbs (?String, ?Hash[untyped, untyped]) -> void
    def initialize(path='OEBPS/package.opf', attributes={})
      @path = path
      if File.extname(@path) != '.opf'
        if @path.size > 0
          @path = [path,'package.opf'].join('/')
        end
      end
      @contents_prefix = File.dirname(@path).sub(/^\.$/,'')
      @contents_prefix = @contents_prefix + '/' if @contents_prefix.size > 0
      @prefixes = {}
      @namespaces = {'xmlns' => OPF_NS }
      @attributes = attributes
      @attributes['version'] ||= '3.0'
      @id_pool = IDPool.new
      @metadata = Metadata.new(version)
      @manifest = Manifest.new(version)
      @spine = Spine.new(version)
      @bindings = Bindings.new
      @epub_backward_compat = true
      yield self if block_given?
    end

    ['unique-identifier', 'xml:lang', 'dir', 'prefix', 'id'].each {
      |name|
      methodbase = name.gsub('-','_').sub('xml:lang', 'lang')
      define_method(methodbase + '=') { |val| @attributes[name] =  val }
      define_method('set_' + methodbase) { |val|
        warn "set_#{methodbase} is obsolete. use #{methodbase} instead."
        @attributes[name] = val
      }        
      define_method(methodbase, ->(val=UNASSIGNED) {
                      if unassigned?(val)
                        @attributes[name]
                      else
                        send(methodbase + '=', val)
                      end
                    })
    }

    # get +attribute+
    # @rbs (String) -> String
    def [](attribute)
      @attributes[attribute]
    end

    # set +attribute+
    # @rbs (String, String) -> void
    def []=(attribute, value)
      @attributes[attribute] = value
    end

    # @rbs (?untyped) -> String?
    def identifier(identifier=UNASSIGNED)
      if unassigned?(identifier)
        @metadata.identifier_by_id(unique_identifier)
      else
        self.identifier=(identifier)
      end
    end
    
    # @rbs (String) -> GEPUB::Meta
    def identifier=(identifier)
      primary_identifier(identifier, nil, nil)
    end
    
    # @rbs (String, ?String?, ?String?) -> GEPUB::Meta
    def primary_identifier(identifier, id = nil, type = nil)
      unique_identifier(id || @id_pool.generate_key(:prefix => 'BookId', :without_count => true))
      @metadata.add_identifier identifier, unique_identifier, type
    end

    # @rbs (String, ?content: nil | String | File | StringIO, ?id: nil | String, ?attributes: Hash[untyped, untyped]) -> GEPUB::Item
    def add_item(href, content:nil, id: nil, attributes: {})
      item = @manifest.add_item(id, href, nil, attributes)
      item.add_content(content) unless content.nil?
      @spine.push(item) if @ordered
      yield item if block_given?
      item
    end

    # @rbs () -> nil
    def ordered
      raise 'need block.' if !block_given?
      @ordered = true
      yield
      @ordered = nil
    end

    # @rbs (String, ?content: nil | StringIO, ?id: nil | String, ?attributes: Hash[untyped, untyped]) -> GEPUB::Item
    def add_ordered_item(href, content:nil, id: nil, attributes: {})
      raise 'do not call add_ordered_item within ordered block.' if @ordered
      item = add_item(href, attributes: attributes, id:id, content: content)
      @spine.push(item)
      item
    end

    # @rbs () -> Array[untyped]
    def spine_items
      spine.itemref_list.map {
        |itemref|
        @manifest.item_list[itemref.idref]
      }
    end

    # @rbs () -> Hash[untyped, untyped]
    def items
      @manifest.item_list
    end
    
    # @rbs (?String) -> String
    def version(val=UNASSIGNED)
      if unassigned?(val)
        @attributes['version']
      else
        @attributes['version'] = val
        @metadata.opf_version = val
        @manifest.opf_version = val
        @spine.opf_version = val
      end
    end

    def set_version(val)
      warn 'set_version is obsolete: use verion instead.'
      @attributes['version'] = val
      @metadata.opf_version = val
      @manifest.opf_version = val
      @spine.opf_version = val
    end

    # @rbs (String) -> String
    def version=(val)
      version(val)
    end
    
    # @rbs () -> String
    def enable_rendition
      @prefixes['rendition'] = 'http://www.idpf.org/vocab/rendition/#'
    end

    def rendition_enabled?
      @prefixes['rendition'] == 'http://www.idpf.org/vocab/rendition/#'      
    end

    # @rbs () -> String
    def enable_ibooks_vocabulary
      @prefixes['ibooks'] = 'http://vocabulary.itunes.apple.com/rdf/ibooks/vocabulary-extensions-1.0/'
    end

    def ibooks_vocabulary_enabled?
      @prefixes['ibooks'] == 'http://vocabulary.itunes.apple.com/rdf/ibooks/vocabulary-extensions-1.0/'
    end
    
    # @rbs () -> String
    def opf_xml
      if version.to_f < 3.0 || @epub_backward_compat
        spine.toc  ||= 'ncx'
        if @metadata.oldstyle_meta.select {
          |meta|
          meta['name'] == 'cover'
          }.length == 0
          
          @manifest.item_list.each {
            |_k, item|
            if item.properties && item.properties.member?('cover-image')
              @metadata.add_oldstyle_meta(nil, 'name' => 'cover', 'content' => item.id)
            end
          }
        end
      end
      if @metadata.rendition_specified? || @spine.rendition_specified? 
        enable_rendition
      end
      if @metadata.ibooks_vocaburaly_specified?
        enable_ibooks_vocabulary
      end

      builder = Nokogiri::XML::Builder.new {
        |xml|
        if @prefixes.size == 0
          @attributes.delete 'prefix'
        else
          @attributes['prefix'] = @prefixes.map { |k, v| "#{k}: #{v}" }.join(' ')
        end
        
        xml.package(@namespaces.merge(@attributes)) {
          @metadata.to_xml(xml)
          @manifest.to_xml(xml)
          @spine.to_xml(xml)
          @bindings.to_xml(xml)
        }
      }
      builder.to_xml(:encoding => 'utf-8')
    end


  end
end
