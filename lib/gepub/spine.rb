require 'rubygems'
require 'nokogiri'
module GEPUB
  class Spine
    include XMLUtil

    class Itemref
      def self.create(parent, attributes = {})
        Itemref.new(attributes['idref'], parent, attributes.reject{|k,v| k == 'idref'})
      end
      
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

      def [](x)
        @attributes[x]
      end

      def []=(x,y)
        @attributes[x] = y
      end
      
      def add_property(property)
        (@attributes['properties'] ||=[]) << property
      end

      def to_xml(builder)
        builder.itemref(@attributes)
      end
    end    

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

    def initialize(opf_version = '3.0', id_pool  = Package::IDPool.new)
      @id_pool = id_pool
      @attributes = {}
      @item_refs = []
      @opf_version = opf_version
      yield self if block_given?
    end

    ['id', 'toc', 'page-progression-direction'].each { |name|
      methodbase = name.gsub('-','_')
      define_method(methodbase + '=') { |val| @attributes[name] = val }
      define_method('set_' + methodbase) { |val| @attributes[name] = val }
      define_method(methodbase) { @attributes[name] }
    }
    
    def itemref_list
      @item_refs.dup
    end

    def push(item)
      @item_refs << i = Itemref.new(item.id, self)
      i
    end

    def <<(item)
      push item
    end
    
    def to_xml(builder)
      builder.spine(@attributes) {
        @item_refs.each {
          |ref|
          ref.to_xml(builder)
        }
      }
    end

    def register_itemref(itemref)
      raise "id '#{itemref.id}' is already in use." if @id_pool[itemref.id]
      @id_pool[itemref.id] = true unless itemref.id.nil?
    end

    def unregister_itemref(itemref)
      @item_refs.delete itemref
      @id_pool[itemref.id] = nil
    end
    
    
  end
end
