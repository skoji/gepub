require 'rubygems'
require 'nokogiri'

module GEPUB
  # Holds data in /package/metadata 
  class Metadata
    include XMLUtil
    attr_reader :opf_version, :other_meta

    # Holds one metadata with refine meta elements.
    class Meta
      attr_accessor :content
      attr_reader :name
      def initialize(name, content, parent, attributes= {}, refiners = {})
        @name = name
        @content = content
        @attributes = attributes
        @refiners = refiners
        @parent = parent
        @parent.add_meta(self) unless @parent.nil?
      end

      def [](x)
        @attributes[x]
      end

      def []=(x,y)
        @attributes[x] = y
      end

      def refiner_list(name)
        return @refiners[name] 
      end

      def refiner(name)
        refiner_node(name)
      end

      def refiner_node(name)
        refiner = @refiners[name]
        if refiner.nil? || refiner.size == 0
          nil
        else
          refiner[0]
        end
      end

      # add a refiner.
      def add_refiner(property, content, attributes = {})
        (@refiners[property] ||= []) << Meta.new('meta', content, @parent, { 'property' => property }.merge(attributes))
      end

      # add a 'unique' refiner. all other refiners with same property will be removed.
      def set_refiner(property, content, attributes = {})
        @refiners[property]= []
        add_refiner(property, content, attributes)
      end

      def to_s(locale=nil)
        localized = nil
        if !locale.nil?
          prefix = locale.sub(/^(.+?)-.*/, '\1')
          regex = Regexp.new("^((" + locale.split('-').join(')?-?(') + ")?)")
          candidates = @refiners['alternate-script'].select {
            |refiner|
            refiner['lang'] =~ /^#{prefix}-?.*/
          }.sort_by {
            |x|
            x['lang'] =~ regex; $1.size
          }.reverse
          localized = candidates[0].content if candidates.size > 0
        end
        localized || @content || super
      end
    end
      
    # parse metadata element. metadata_xml should be Nokogiri::XML::Node object.
    def self.parse(metadata_xml, opf_version = '3.0')
      Metadata.new(opf_version) {
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

          @xml.xpath("#{prefix(OPF_NS)}:meta[not(@refines) and @property]", @namespaces).each {
            |node|
            @meta[node['property']] = create_meta(node)
          }

          @other_meta = parse_opf2_meta
        }
      }
    end
    
    def initialize(opf_version = '3.0')
      @idlist = {}
      @content_nodes = {}
      @meta = {}
      @other_meta = []
      @opf_version = opf_version
      @namespaces = { 'xmlns:dc' =>  DC_NS }
      @namespaces['xmlns:opf'] = OPF_NS if @opf_version.to_f < 3.0 
      yield self if block_given?
    end

    def main_title # should make it obsolete? 
      @content_nodes['title'][0].content
    end

    
    CONTENT_NODE_LIST = ['identifier','title', 'language', 'creator', 'coverage','creator','date','description','format ','publisher','relation','rights','source','subject','type'].each {
      |node|
      define_method(node + '_list') { @content_nodes[node] } 

      #TODO: should override for 'title'. // for 'main title' not always comes first.
      define_method(node) {
        if !@content_nodes[node].nil? && @content_nodes[node].size > 0
          @content_nodes[node][0]
        end
      }
    }

    def set_identifier(string, id, type=nil)
      if !(identifier = @idlist[id]).nil?
        raise 'id #{id} is already in use' if identifier.name != 'identifier'
        identifier.content = string
      else
        identifier = Meta.new('identifier', string, self, { 'id' => id })
        @content_nodes['identifier'] ||= [] << identifier
      end
      identifier.set_refiner('identifier-type', type)
    end

    def add_creator(content, id = nil, role = 'aut', seq = 1, file_as = nil, alternates = {})
      raise 'id #{id} is already in use' if !(creator = @idlist[id]).nil?
      creator = Meta.new('creator',
                         content,
                         self,
                         { 'id' => id },
                         { 'alternate-script' =>
                           alternates.map {
                             |locale, content|
                             Meta.new('meta', content, self, { 'property' => 'alternate-script', 'lang' => locale })
                           }})
      creator.set_refiner('role', role)
      @content_nodes['creator'] ||= [] << creator
    end
    
    def add_meta(meta)
      @idlist[meta['id']] =  meta unless meta['id'].nil?
    end
    
    private
    def parse_node(ns, node)
      @xml.xpath("#{prefix(ns)}:#{node}", @namespaces).map {
        |node|
        create_meta(node)
      }
    end

    def create_meta(node)
      Meta.new(node.name, node.content, self, node.attributes, collect_refiners(node['id']))
    end

    def collect_refiners(id)
      r = {}
      if !id.nil? 
        @xml.xpath("//#{prefix(OPF_NS)}:meta[@refines='##{id}\']", @namespaces).each {
          |node|
          (r[node['property']] ||= []) << create_meta(node)
        }
      end
      r
    end

    def parse_opf2_meta
      @xml.xpath("#{prefix(OPF_NS)}:meta[not(@refines) and not(@property)]").map {
            |node|
            create_meta(node)
      }
    end
  end
end
