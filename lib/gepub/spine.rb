require 'rubygems'
require 'nokogiri'
module GEPUB
  class Spine
    include XMLUtil
    include InspectMixin

    attr_accessor :opf_version
    class Itemref
      # @rbs (GEPUB::Spine, ?Hash[untyped, untyped]) -> GEPUB::Spine::Itemref
      def self.create(parent, attributes = {})
        Itemref.new(attributes['idref'], parent, attributes.reject{|k,_v| k == 'idref'})
      end
      
      # @rbs (String, ?GEPUB::Spine, ?Hash[untyped, untyped]) -> void
      def initialize(idref, parent = nil, attributes = {})
        if attributes['properties'].class == String
          attributes['properties'] = attributes['properties'].split(' ')
        end
        @attributes = {'idref' => idref}.merge(attributes)
        @parent = parent
        @parent.register_itemref(self) unless @parent.nil?
        self
      end

      ['idref', 'linear', 'id', 'properties'].each { |name|
        methodbase = name.gsub('-','_')
        define_method(methodbase + '=') { |val| @attributes[name] = val }
        define_method('set_' + methodbase) { |val| @attributes[name] = val }
        define_method(methodbase) { @attributes[name] }
      }

      # get +attribute+
      def [](attribute)
        @attributes[attribute]
      end

      # set +attribute+
      def []=(attribute, value)
        @attributes[attribute] = value
      end

      # @rbs (String) -> Array[untyped]
      def add_property(property)
        (@attributes['properties'] ||=[]) << property
      end

      # @rbs () -> Array[untyped]
      def page_spread_right
        add_property 'page-spread-right'
      end

      # @rbs () -> Array[untyped]
      def page_spread_left
        add_property 'page-spread-left'
      end

      # @rbs () -> bool?
      def rendition_specified?
        @rendition_specified
      end

      # @rbs (String, String) -> bool
      def set_rendition_param(name, val)
        add_property "rendition:#{name}-#{val}"
        @rendition_specified = true
      end

      # @rbs (String) -> bool
      def rendition_layout=(val)
        set_rendition_param('layout', val)
      end

      # @rbs (String) -> bool
      def rendition_orientation=(val)
        set_rendition_param('orientation', val)
      end

      # @rbs (String) -> bool
      def rendition_spread=(val)
        set_rendition_param('spread', val)
      end

      # @rbs (Nokogiri::XML::Builder, String) -> Nokogiri::XML::Builder::NodeBuilder
      def to_xml(builder, opf_version)
        attr = @attributes.dup
        if opf_version.to_f < 3.0
          attr.reject!{ |k,_v| k == 'properties' }
        end
        if !attr['properties'].nil?
          attr['properties'] = attr['properties'].join(' ')
          if attr['properties'].size == 0
            attr.delete 'properties'
          end
        end
        builder.itemref(attr)
      end
    end    

    # @rbs (Nokogiri::XML::Element, ?String, ?GEPUB::Package::IDPool) -> GEPUB::Spine
    def self.parse(spine_xml, opf_version = '3.0', id_pool  = Package::IDPool.new)
      Spine.new(opf_version, id_pool) {
        |spine|
        spine.instance_eval {
          @xml = spine_xml
          @namespaces = @xml.namespaces
          @attributes = attr_to_hash(@xml.attributes)
          @item_refs = []
          @xml.xpath("//#{ns_prefix(OPF_NS)}:spine/#{ns_prefix(OPF_NS)}:itemref", @namespaces).map {
            |itemref|
            i = Itemref.create(self, attr_to_hash(itemref.attributes))
            @item_refs << i
          }
        }
      }
    end

    # @rbs (?String, ?GEPUB::Package::IDPool) -> void
    def initialize(opf_version = '3.0', id_pool  = Package::IDPool.new)
      @id_pool = id_pool
      @attributes = {}
      @item_refs = []
      @itemref_by_id = {}
      @opf_version = opf_version
      yield self if block_given?
    end

    ['id', 'toc', 'page-progression-direction'].each { |name|
      methodbase = name.gsub('-','_')
      define_method(methodbase + '=') { |val| @attributes[name] = val }
      define_method('set_' + methodbase) { |val| @attributes[name] = val }
      define_method(methodbase) { @attributes[name] }
    }
    
    # @rbs () -> Array[untyped]
    def itemref_list
      @item_refs.dup
    end

    # @rbs () -> Hash[untyped, untyped]
    def itemref_by_id
      @itemref_by_id.dup
    end
    
    # @rbs (GEPUB::Item) -> GEPUB::Spine::Itemref
    def push(item)
      @item_refs << i = Itemref.new(item.id, self)
      @itemref_by_id[item.id] = i
      i
    end

    def <<(item)
      push item
    end

    # @rbs () -> bool
    def rendition_specified?
      @item_refs.select { |itemref| itemref.rendition_specified? }.size > 0
    end
    
    # @rbs (Nokogiri::XML::Builder) -> Nokogiri::XML::Builder::NodeBuilder
    def to_xml(builder)
      builder.spine(@attributes) {
        @item_refs.each {
          |ref|
          ref.to_xml(builder, @opf_version)
        }
      }
    end

    # @rbs (GEPUB::Spine::Itemref) -> nil
    def register_itemref(itemref)
      raise "id '#{itemref.id}' is already in use." if @id_pool[itemref.id]
      @id_pool[itemref.id] = true unless itemref.id.nil?
    end

    def unregister_itemref(itemref)
      @item_refs.delete itemref
      @id_pool[itemref.id] = nil
    end

    # @rbs (Array[untyped]) -> Array[untyped]
    def remove_with_idlist(ids)
      @item_refs = @item_refs.select {
        |ref|
        !ids.member? ref.idref
      }
    end
    
  end
end
