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
    class NilContent
      def self.content
        nil
      end
    end
    include XMLUtil, DSLUtil
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
            @content_nodes[node] = parse_node(DC_NS, node).sort_as_meta
          }
          @xml.xpath("#{ns_prefix(OPF_NS)}:meta[not(@refines) and @property]", @namespaces).each {
            |node|
            (@content_nodes['meta'] ||= []) << create_meta(node)
          }

          @oldstyle_meta = parse_opf2_meta

          meta_list.each {
            |metanode|
            case metanode['property']
            when 'rendition:layout'
              @layout = metanode
            when 'rendition:orientation'          
              @orientation = metanode
            when 'rendition:spread'
              @spread = metanode
            when 'ibooks:version'
              @ibooks_version = metanode
            when 'ibooks:scroll-axis'
              @ibooks_scroll_axis = metanode
            end

          }
        }
      }
    end
    
    def initialize(opf_version = '3.0',id_pool = Package::IDPool.new)
      @id_pool = id_pool
      @metalist = {}
      @content_nodes = {}
      @oldstyle_meta = []
      @opf_version = opf_version
      @namespaces = { 'xmlns:dc' =>  DC_NS }
      @namespaces['xmlns:opf'] = OPF_NS if @opf_version.to_f < 3.0
      @default_layout = 'reflowable'
      @default_orientation = 'auto'
      @default_spread = 'auto'
      @layout = NilContent
      @orientation = NilContent
      @spread = NilContent
      @ibooks_version = NilContent
      @ibooks_scroll_axis = NilContent
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
      title.to_s
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
    
    CONTENT_NODE_LIST = ['identifier', 'title', 'language', 'contributor', 'creator', 'coverage', 'date','description','format','publisher','relation','rights','source','subject','type'].each {
      |node|
      define_method(node + '_list') { @content_nodes[node].dup.sort_as_meta }
      define_method(node + '_clear') {
        if !@content_nodes[node].nil?
          @content_nodes[node].each { |x| unregister_meta(x) };
          @content_nodes[node] = []
        end
      }

      next if node == 'title'

      define_method(node, ->(content=UNASSIGNED, id=nil) {
                      if unassigned?(content)
                        get_first_node(node)
                      else
                        send(node + "_clear")
                        add_metadata(node, content, id)
                      end
                    })

      define_method('set_' + node) {
        |content, id|
        warn "obsolete : set_#{node}. use #{node} instead."
        send(node + "_clear")
        add_metadata(node, content, id)
      }
      
      define_method(node+'=') {
        |content|
        send(node + "_clear")
        if node == 'date'
          add_date(content, nil)
        else
          add_metadata(node, content, nil)
        end
      }

      next if ["identifier", "date", "creator", "contributor"].include?(node)

      define_method('add_' + node) {
        |content, id|
        add_metadata(node, content, id)
      }
    }

    def meta_list
      (@content_nodes['meta'] || []).sort_as_meta.dup
    end

    def meta_clear
      if !@content_nodes['meta'].nil?
        @content_nodes['meta'].each { |x| unregister_meta(x) };
        @content_nodes['meta'] = []
      end
    end

    def title=(content)
      title(content)
    end

    def title(content=UNASSIGNED, id = nil, title_type = nil)
      if unassigned?(content)
        if !@content_nodes['title'].nil?
          @content_nodes['title'].each do
            |titlenode|
            return titlenode if titlenode.title_type.to_s == TITLE_TYPE::MAIN
          end
        end
        get_first_node('title')
      else
        title_clear
        meta = add_title(content, id, title_type)
        yield meta if block_given?
        meta
      end
    end

    
    def get_first_node(node)
      if !@content_nodes[node].nil? && @content_nodes[node].size > 0
        @content_nodes[node].sort_as_meta[0]
      end
    end

    def add_identifier(string, id=nil, type=nil)
      id = @id_pool.generate_key(:prefix => 'BookId') if id.nil?
      raise "id #{id} is already in use" if @id_pool[id]
      identifier = add_metadata('identifier', string, id)
      identifier.refine('identifier-type', type) unless type.nil?
      identifier
    end

    def add_date(date, id)
      add_metadata('date', date, id, DateMeta)
    end

    def identifier_by_id(id)
      @content_nodes['identifier'].each {
        |x|
        return x.content if x['id'] == id
      }
      return nil
    end
    
    def add_metadata(name, content, id = nil, itemclass = Meta)
      meta = itemclass.new(name, content, self, { 'id' => id })
      (@content_nodes[name] ||= []) << meta
      yield meta if block_given?
      meta
    end

    def add_title(content, id = nil, title_type = nil)
      meta = add_metadata('title', content, id).refine('title-type', title_type)
      yield meta if block_given?
      meta
    end

    def set_title(content, id = nil, title_type = nil)
      warn "obsolete : set_title. use title or title= instead."
      title_clear
      meta = add_title(content, id, title_type)
      yield meta if block_given?
      meta
    end
    
    def add_person(name, content, id = nil, role = nil)
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

    def lastmodified(date=UNASSIGNED)
      if unassigned?(date)
        ret = (@content_nodes['meta'] ||=[]).select {
          |meta|
          meta['property'] == 'dcterms:modified'
        }
        ret.size == 0 ? nil : ret[0]
      else
        date ||= Time.now
        (@content_nodes['meta'] ||= []).each {
          |meta|
          if (meta['property'] == 'dcterms:modified')
            @content_nodes['meta'].delete meta
          end
        }
        add_metadata('meta', date.utc.strftime('%Y-%m-%dT%H:%M:%SZ'), nil, DateMeta)['property'] = 'dcterms:modified'
      end
    end

    def modified_now
      lastmodified Time.now
    end

    def lastmodified=(date)
      lastmodified(date)
    end
    
    def set_lastmodified(date=nil)
      warn "obsolete : set_lastmodified. use lastmodified instead."
      date ||= Time.now
      (@content_nodes['meta'] ||= []).each {
        |meta|
        if (meta['property'] == 'dcterms:modified')
          @content_nodes['meta'].delete meta
        end
      }
      add_metadata('meta', date.utc.strftime('%Y-%m-%dT%H:%M:%SZ'), nil, DateMeta)['property'] = 'dcterms:modified'
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

    def rendition_layout
      @layout.content || @default_layout
    end

    def rendition_layout=(val)
      @layout = Meta.new('meta', val, self, { 'property' => 'rendition:layout' })
      (@content_nodes['meta'] ||= []) << @layout
    end

    def rendition_orientation
      @orientation.content || @default_orientation
    end

    def rendition_orientation=(val)
      @orientation = Meta.new('meta', val, self, { 'property' => 'rendition:orientation' })
      (@content_nodes['meta'] ||= []) << @orientation
    end

    def rendition_spread
      @spread.content || @default_spread
    end

    def rendition_spread=(val)
      @spread = Meta.new('meta', val, self, { 'property' => 'rendition:spread' })
      (@content_nodes['meta'] ||= []) << @spread
    end

    def ibooks_version
      @ibooks_version.content || ''
    end

    def ibooks_version=(val)
      @ibooks_version = Meta.new('meta', val, self, { 'property' => 'ibooks:version' })
      (@content_nodes['meta'] ||= []) << @ibooks_version
    end

    def ibooks_scroll_axis
      @ibooks_scroll_axis.content || ''      
    end

    def ibooks_scroll_axis=(val)
      if ![:vertical, :horizontal, :default].member? val.to_sym
        raise 'ibooks_scroll_axis should be one of vertical, horizontal or default'
      end
      @ibooks_scroll_axis = Meta.new('meta', val, self, { 'property' => 'ibooks:scroll-axis' })
      (@content_nodes['meta'] ||= []) << @ibooks_scroll_axis
    end
    
    def rendition_specified?
      @layout.content || @orientation.content || @spread.content
    end

    def ibooks_vocaburaly_specified?
      @ibooks_version.content || @ibooks_scroll_axis.content
    end
    
    private
    def parse_node(ns, node)
      @xml.xpath("#{ns_prefix(ns)}:#{node}", @namespaces).map {
        |n|
        create_meta(n)
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
      @xml.xpath("#{ns_prefix(OPF_NS)}:meta[not(@refines) and not(@property)]", @namespaces).map {
            |node|
            create_meta(node)
      }
    end
  end
end
