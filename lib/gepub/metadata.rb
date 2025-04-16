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
      # @rbs () -> nil
      def self.content
        nil
      end
    end
    include XMLUtil, DSLUtil
    include InspectMixin

    attr_accessor :opf_version
    # parse metadata element. metadata_xml should be Nokogiri::XML::Node object.
    # @rbs (Nokogiri::XML::Element, ?String, ?GEPUB::Package::IDPool) -> GEPUB::Metadata
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
        # do not set @lastmodified_updated here
      }
    end
    
    # @rbs (?String, ?GEPUB::Package::IDPool) -> void
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
      @lastmodified_updated = false
      yield self if block_given?
    end

    # @rbs () -> bool
    def lastmodified_updated?
      @lastmodified_updated
    end

    # @rbs (Nokogiri::XML::Builder) -> nil
    def to_xml(builder) 
      builder.metadata(@namespaces) {
        @content_nodes.each {
          |_name, list|
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

    # @rbs () -> String
    def main_title # should make it obsolete? 
      title.to_s
    end

    # @rbs () -> Array[untyped]
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
    
    # @rbs () -> Array[untyped]
    def meta_list
      (@content_nodes['meta'] || []).sort_as_meta.dup
    end

    def meta_clear
      if !@content_nodes['meta'].nil?
        @content_nodes['meta'].each { |x| unregister_meta(x) };
        @content_nodes['meta'] = []
      end
    end

    # @rbs (String) -> GEPUB::Meta
    def title=(content)
      title(content)
    end

    # @rbs (?String, ?id: nil, ?title_type: nil) -> GEPUB::Meta?
    def title(content=UNASSIGNED, id: nil, title_type: nil)
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
        meta = add_title(content, id: id, title_type: title_type)
        yield meta if block_given?
        meta
      end
    end

    
    # @rbs (String) -> (GEPUB::Meta | GEPUB::DateMeta)?
    def get_first_node(node)
      if !@content_nodes[node].nil? && @content_nodes[node].size > 0
        @content_nodes[node].sort_as_meta[0]
      end
    end

    # @rbs (String, ?String?, ?String?) -> GEPUB::Meta
    def add_identifier(string, id=nil, type=nil)
      id = @id_pool.generate_key(:prefix => 'BookId') if id.nil?
      raise "id #{id} is already in use" if @id_pool[id]
      identifier = add_metadata('identifier', string, id: id)
      identifier.refine('identifier-type', type) unless type.nil?
      identifier
    end

    # @rbs (String | Time, ?String?, ?id: nil) -> GEPUB::DateMeta
    def add_date(date, deprecated_id = nil, id: nil)
      if deprecated_id
        warn "secound argument is deprecated. use id: keyword argument"
        id = deprecated_id
      end
      add_metadata('date', date, id: id, itemclass: DateMeta)
    end

    # @rbs (String?) -> String?
    def identifier_by_id(id)
      (@content_nodes['identifier'] || []).each {
        |x|
        return x.content if x['id'] == id
      }
      return nil
    end
    
    # @rbs (String, String | Time, ?id: String | nil, ?itemclass: Class) -> (GEPUB::Meta | GEPUB::DateMeta)?
    def add_metadata_internal(name, content, id: nil, itemclass: Meta)
      meta = itemclass.new(name, content, self, { 'id' => id })
      (@content_nodes[name] ||= []) << meta
      meta
    end

    # @rbs (?Time | String) -> (String | GEPUB::DateMeta | GEPUB::Meta)?
    def lastmodified(date=UNASSIGNED)
      if unassigned?(date)
        ret = (@content_nodes['meta'] ||=[]).select {
          |meta|
          meta['property'] == 'dcterms:modified'
        }
        ret.size == 0 ? nil : ret[0]
      else
        @lastmodified_updated = true
        date ||= Time.now
        date = DateTime.parse(date) if date.is_a? String
        (@content_nodes['meta'] ||= []).each {
          |meta|
          if (meta['property'] == 'dcterms:modified')
            @content_nodes['meta'].delete meta
          end
        }
        add_metadata('meta', date.to_time.utc.strftime('%Y-%m-%dT%H:%M:%SZ'), itemclass: DateMeta)['property'] = 'dcterms:modified'
      end
    end

    # @rbs () -> String
    def modified_now
      lastmodified Time.now
    end

    # @rbs (Time | String) -> String
    def lastmodified=(date)
      lastmodified(date)
    end
    
    def set_lastmodified(date=nil)
      warn "obsolete : set_lastmodified. use lastmodified instead."
      lastmodified(date)
    end

    # @rbs (nil, ?Hash[untyped, untyped]) -> GEPUB::Meta
    def add_oldstyle_meta(content, attributes = {})
      meta = Meta.new('meta', content, self, attributes)
      (@oldstyle_meta ||= []) << meta
      meta
    end

    
    # @rbs (GEPUB::Meta | GEPUB::DateMeta) -> bool?
    def register_meta(meta)
      if !meta['id'].nil?
        raise "id '#{meta['id']}' is already in use." if @id_pool[meta['id']]
        @metalist[meta['id']] =  meta 
        @id_pool[meta['id']] = true
      end
    end

    # @rbs (GEPUB::Meta) -> nil
    def unregister_meta(meta)
      if meta['id'].nil?
        @metalist[meta['id']] =  nil
        @id_pool[meta['id']] = nil
      end
    end

    # @rbs () -> String
    def rendition_layout
      @layout.content || @default_layout
    end

    # @rbs (String) -> Array[untyped]
    def rendition_layout=(val)
      @layout = Meta.new('meta', val, self, { 'property' => 'rendition:layout' })
      (@content_nodes['meta'] ||= []) << @layout
    end

    # @rbs () -> String
    def rendition_orientation
      @orientation.content || @default_orientation
    end

    # @rbs (String) -> Array[untyped]
    def rendition_orientation=(val)
      @orientation = Meta.new('meta', val, self, { 'property' => 'rendition:orientation' })
      (@content_nodes['meta'] ||= []) << @orientation
    end

    # @rbs () -> String
    def rendition_spread
      @spread.content || @default_spread
    end

    # @rbs (String) -> Array[untyped]
    def rendition_spread=(val)
      @spread = Meta.new('meta', val, self, { 'property' => 'rendition:spread' })
      (@content_nodes['meta'] ||= []) << @spread
    end

    def ibooks_version
      @ibooks_version.content || ''
    end

    # @rbs (String) -> Array[untyped]
    def ibooks_version=(val)
      @ibooks_version = Meta.new('meta', val, self, { 'property' => 'ibooks:version' })
      (@content_nodes['meta'] ||= []) << @ibooks_version
    end

    def ibooks_scroll_axis
      @ibooks_scroll_axis.content || ''      
    end

    # @rbs (Symbol) -> Array[untyped]
    def ibooks_scroll_axis=(val)
      if ![:vertical, :horizontal, :default].member? val.to_sym
        raise 'ibooks_scroll_axis should be one of vertical, horizontal or default'
      end
      @ibooks_scroll_axis = Meta.new('meta', val, self, { 'property' => 'ibooks:scroll-axis' })
      (@content_nodes['meta'] ||= []) << @ibooks_scroll_axis
    end
    
    # @rbs () -> String?
    def rendition_specified?
      @layout.content || @orientation.content || @spread.content
    end

    # @rbs () -> (String | Symbol)?
    def ibooks_vocaburaly_specified?
      @ibooks_version.content || @ibooks_scroll_axis.content
    end
    
    private
    # @rbs (String, String) -> Array[untyped]
    def parse_node(ns, node)
      @xml.xpath("#{ns_prefix(ns)}:#{node}", @namespaces).map {
        |n|
        create_meta(n)
      }
    end
    
    # @rbs (Nokogiri::XML::Element) -> GEPUB::Meta
    def create_meta(node)
      Meta.new(node.name, node.content, self, attr_to_hash(node.attributes), collect_refiners(node['id']))
    end

    # @rbs (String?) -> Hash[untyped, untyped]
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

    # @rbs () -> Array[untyped]
    def parse_opf2_meta
      @xml.xpath("#{ns_prefix(OPF_NS)}:meta[not(@refines) and not(@property)]", @namespaces).map {
            |node|
            create_meta(node)
      }
    end
  end
end
