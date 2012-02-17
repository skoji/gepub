require 'rubygems'
require 'nokogiri'
module GEPUB
  class Manifest
    include XMLUtil
    def self.parse(manifest_xml, opf_version = '3.0', id_pool = PackageData::IDPool.new)
      Manifest.new(opf_version, id_pool) {
        |manifest|
        manifest.instance_eval {
          @xml = manifest_xml
          @namespaces = @xml.namespaces
          @items = {}
          @xml.xpath("//#{prefix(OPF_NS)}:manifest/#{prefix(OPF_NS)}:item", @namespaces).map {
            |item|
            i = Item.create(self, attr_to_hash(item.attributes))
            @items[i.id] = i
          }
        }
      }
    end

    def initialize(opf_version = '3.0', id_pool = PackageData::IDPool.new)
      @id_pool = id_pool
      @items = {}
      @opf_version = opf_version
      yield self if block_given?
    end

    def item_list
      @items.dup
    end

    def add_item(id,href,media_type, attributes = {})
      @items[id] = item = Item.new(id,href,media_type,self, attributes)
      item
    end

    def register_item(item)
      raise "id '#{item.id}' is already in use." if @id_pool[item.id]
      @id_pool[item.id] = true
    end

    def unregister_item(item)
      @items[item.id] = nil
      @id_pool[item.id] = nil
    end
  end
end
