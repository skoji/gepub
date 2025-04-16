require 'rubygems'
require 'nokogiri'
module GEPUB
  class Manifest
    include XMLUtil
    include InspectMixin

    attr_accessor :opf_version
    # @rbs (Nokogiri::XML::Element, ?String, ?GEPUB::Package::IDPool) -> GEPUB::Manifest
    def self.parse(manifest_xml, opf_version = '3.0', id_pool = Package::IDPool.new)
      Manifest.new(opf_version, id_pool) {
        |manifest|
        manifest.instance_eval {
          @xml = manifest_xml
          @namespaces = @xml.namespaces
          @attributes = attr_to_hash(@xml.attributes)
          @items = {}
          @items_by_href = {}
          @xml.xpath("//#{ns_prefix(OPF_NS)}:manifest/#{ns_prefix(OPF_NS)}:item", @namespaces).map {
            |item|
            i = Item.create(self, attr_to_hash(item.attributes))
            @items[i.id] = i
            @items_by_href[i.href] = i
          }
        }
      }
    end

    def id=(val)
      @attributes['id'] = val
    end

    def id
      @attributes['id']
    end

    # @rbs (?String, ?GEPUB::Package::IDPool) -> void
    def initialize(opf_version = '3.0', id_pool = Package::IDPool.new)
      @id_pool = id_pool
      @attributes = {}
      @items = {}
      @items_by_href = {}
      @opf_version = opf_version
      yield self if block_given?
    end

    # @rbs () -> Hash[untyped, untyped]
    def item_list
      @items.dup
    end

    def items
      @items.dup      
    end
    
    # @rbs (String) -> GEPUB::Item?
    def item_by_href(href)
      @items_by_href[href]
    end
    
    # @rbs (String?, String, String?, ?Hash[untyped, untyped]) -> GEPUB::Item
    def add_item(id,href,media_type, attributes = {})
      id ||= @id_pool.generate_key(:prefix=>'item_'+ File.basename(href,'.*'), :without_count => true)
      @items[id] = item = Item.new(id,href,media_type,self, attributes)
      @items_by_href[href] = item
      item
    end

    # @rbs (Nokogiri::XML::Builder) -> Nokogiri::XML::Builder::NodeBuilder
    def to_xml(builder)
      builder.manifest(@attributes) {
        @items.each {
          |_itemid, item|
          item.to_xml(builder, @opf_version)
        }
      }
    end
    
    # @rbs (GEPUB::Item) -> bool
    def register_item(item)
      raise "id '#{item.id}' is already in use." if @id_pool[item.id]
      @id_pool[item.id] = true
    end

    def unregister_item(item)
      @items.delete(item.id)
      @items_by_href.delete(item.href)
      @id_pool[item.id] = nil
    end
    
  end
end
