require 'rubygems'
require 'nokogiri'
require 'time'

module GEPUB
  # metadata constants
  module TITLE_TYPE
    TYPES = ['main','subtitle', 'short', 'collection', 'edition','expanded'].each {
      |type|
      const_set(type.upcase, type)
    }
  end
  # Holds data in /package/metadata 
  class Metadata
    include XMLUtil
    attr_accessor :opf_version
    # parse metadata element. metadata_xml should be Nokogiri::XML::Node object.
    def self.parse(metadata_xml, opf_version = '3.0', id_pool = Package::IDPool.new)
      Metadata.new(opf_version, id_pool) {
        |metadata|
        metadata.instance_eval {
          @xml = metadata_xml
          @namespaces = @xml.namespaces
          CONTENT_NODE_LIST.each {
            |node|
            i = 0
            @content_nodes[node] = parse_node(DC_NS, node).sort_by {
              |v|
              [v.refiner('display-seq').to_s.to_i || 2 ** (0.size * 8 - 2) - 1, i += 1]
            }              
          }
          @xml.xpath("#{ns_prefix(OPF_NS)}:meta[not(@refines) and @property]", @namespaces).each {
            |node|
            @meta[node['property']] = create_meta(node)
          }

          @oldstyle_meta = parse_opf2_meta
        }
      }
    end
    
    def initialize(opf_version = '3.0',id_pool = Package::IDPool.new)
      @id_pool = id_pool
      @metalist = {}
      @content_nodes = {}
      @meta = {}
      @oldstyle_meta = []
      @opf_version = opf_version
      @namespaces = { 'xmlns:dc' =>  DC_NS }
      @namespaces['xmlns:opf'] = OPF_NS if @opf_version.to_f < 3.0 
      yield self if block_given?
    end

    def to_xml(builder)
      builder.metadata(@namespaces) {
        @content_nodes.each {
          |name, list|
          list.each {
            |meta|
            meta.to_xml(builder, @id_pool, ns_prefix(DC_NS), nil, @opf_version)
          }
        }
        @oldstyle_meta.each {
          |node|
          node.to_xml(builder, @id_pool, nil)
        }
      }
      @xml
    end

    def main_title # should make it obsolete? 
      @content_nodes['title'][0].content
    end

    def oldstyle_meta
      @oldstyle_meta.dup
    end

    def oldstyle_meta_clear
      @oldstyle_meta.each {
        |meta|
        unregister_meta(meta)
      }
      @oldstyle_meta = []
    end
    
    CONTENT_NODE_LIST = ['identifier','title', 'language', 'contributor', 'creator', 'coverage', 'date','description','format ','publisher','relation','rights','source','subject','type'].each {
      |node|
      define_method(node + '_list') { @content_nodes[node].dup }
      define_method(node + '_clear') {
        if !@content_nodes[node].nil?
          @content_nodes[node].each { |x| unregister_meta(x) };
          @content_nodes[node] = []
        end
      }

      #TODO: should override for 'title'. // for 'main title' not always comes first.
      define_method(node) {
        if !@content_nodes[node].nil? && @content_nodes[node].size > 0
          @content_nodes[node][0]
        end
      }

      define_method('add_' + node) {
        |content, id|
        add_metadata(node, content, id)
      }
      
      define_method('set_' + node) {
        |content, id|
        send(node + "_clear")
        add_metadata(node, content, id)
      }
      
      define_method(node+'=') {
        |content|
        send(node + "_clear")
        add_metadata(node, content)
      }
    }

    def add_identifier(string, id, type=nil)
      raise 'id #{id} is already in use' if @id_pool[id]
      identifier = add_metadata('identifier', string, id)
      identifier.refine('identifier-type', type) unless type.nil?
      identifier
    end

    def identifier_by_id(id)
      @content_nodes['identifier'].each {
        |x|
        return x.content if x['id'] == id
      }
    end
    
    def add_metadata(name, content, id = nil)
      meta = Meta.new(name, content, self, { 'id' => id })
      (@content_nodes[name] ||= []) << meta
      yield self if block_given?
      meta
    end

    def add_title(content, id = nil, title_type = nil)
      meta = add_metadata('title', content, id).refine('title-type', title_type)
      yield meta if block_given?
      meta
    end

    def set_title(content, id = nil, title_type = nil)
      title_clear
      add_title(content, id, title_type)
      yield meta if block_given?
      meta
    end
    
    def add_person(name, content, id = nil, role = 'aut')
      meta = add_metadata(name, content, id).refine('role', role)
      yield meta if block_given?
      meta
    end

    def add_creator(content, id = nil, role = 'aut')
      meta = add_person('creator', content, id, role)
      yield meta if block_given?
      meta
    end

    def add_contributor(content, id=nil, role=nil)
      meta = add_person('contributor', content, id, role)
      yield meta if block_given?
      meta
    end
    
    def set_lastmodified(date=nil)
      date ||= Time.now
      (@content_nodes['meta'] ||= []).each {
        |meta|
        if (meta['property'] == 'dcterms:modified')
          @content_nodes['meta'].delete meta
        end
      }
      add_metadata('meta', date.utc.strftime('%Y-%m-%dT%H:%M:%SZ'))['property'] = 'dcterms:modified'
    end

    def add_oldstyle_meta(content, attributes = {})
      meta = Meta.new('meta', content, self, attributes)
      (@oldstyle_meta ||= []) << meta
      meta
    end

    
    def register_meta(meta)
      if !meta['id'].nil?
        raise "id '#{meta['id']}' is already in use." if @id_pool[meta['id']]
        @metalist[meta['id']] =  meta 
        @id_pool[meta['id']] = true
      end
    end

    def unregister_meta(meta)
      if meta['id'].nil?
        @metalist[meta['id']] =  nil
        @id_pool[meta['id']] = nil
      end
    end
    
    private
    def parse_node(ns, node)
      @xml.xpath("#{ns_prefix(ns)}:#{node}", @namespaces).map {
        |node|
        create_meta(node)
      }
    end

    def create_meta(node)
      Meta.new(node.name, node.content, self, attr_to_hash(node.attributes), collect_refiners(node['id']))
    end

    def collect_refiners(id)
      r = {}
      if !id.nil? 
        @xml.xpath("//#{ns_prefix(OPF_NS)}:meta[@refines='##{id}']", @namespaces).each {
          |node|
          (r[node['property']] ||= []) << create_meta(node)
        }
      end
      r
    end

    def parse_opf2_meta
      @xml.xpath("#{ns_prefix(OPF_NS)}:meta[not(@refines) and not(@property)]").map {
            |node|
            create_meta(node)
      }
    end
  end
end
