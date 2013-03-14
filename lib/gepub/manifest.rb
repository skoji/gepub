require 'rubygems'
require 'nokogiri'
module GEPUB
  class Manifest
    include XMLUtil
    attr_accessor :opf_version
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

    def initialize(opf_version = '3.0', id_pool = Package::IDPool.new)
      @id_pool = id_pool
      @attributes = {}
      @items = {}
      @items_by_href = {}
      @opf_version = opf_version
      yield self if block_given?
    end

    def item_list
      @items.dup
    end

    def items
      @items.dup      
    end
    
    def item_by_href(href)
      @items_by_href[href]
    end
    
    def add_item(id,href,media_type, attributes = {})
      id ||= @id_pool.generate_key(:prefix=>'item_'+ File.basename(href,'.*'), :without_count => true)
      @items[id] = item = Item.new(id,href,media_type,self, attributes)
      @items_by_href[href] = item
      item
    end

    def to_xml(builder)
      builder.manifest(@attributes) {
        @items.each {
          |itemid, item|
          item.to_xml(builder, @opf_version)
        }
      }
    end
    
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
