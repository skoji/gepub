require 'rubygems'
require 'nokogiri'
module GEPUB
  class Manifest
    include XMLUtil

    class Item
      def self.create(parent, attributes = {})
        Item.new(attributes['id'], attributes['href'], attributes['media-type'], parent,
                 attributes.reject { |k,v| ['id','href','media-type'].member?(k) })
      end

      def initialize(id, href, media_type, parent, attributes = {})
        if attributes['properties'].class == String
          attributes['properties'] = attributes['properties'].split(' ')
        end
        @attributes = {'id' => id, 'href' => href, 'media-type' => media_type}.merge(attributes)
        @parent = parent
        @parent.register_item(self) unless @parent.nil?
        self
      end

      ['id', 'href', 'media-type', 'fallback', 'properties', 'media-overlay'].each { |name|
        methodbase = name.sub('-','_')
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
    end

    def self.parse(manifest_xml, opf_version = '3.0', id_pool = PackageData::IDPool.new)
      Manifest.new(opf_version, id_pool) {
        |manifest|
        manifest.instance_eval {
          @xml = manifest_xml
          @namespaces = @xml.namespaces
          @items = @xml.xpath("//#{prefix(OPF_NS)}:manifest/#{prefix(OPF_NS)}:item", @namespaces).map {
            |item|
            Item.create(self, attr_to_hash(item.attributes))
          }
        }
      }
    end

    def initialize(opf_version = '3.0', id_pool = PackageData::IDPool.new)
      @id_pool = id_pool
      @items = []
      @opf_version = opf_version
      yield self if block_given?
    end

    def item_list
      @items.dup
    end
    
    def register_item(item)
      raise "id '#{item.id}' is already in use." if @id_pool[item.id]
      @id_pool[item.id] = true
    end

    def unregister_item(item)
      @id_pool[item['id']] = nil
    end
  end
end
