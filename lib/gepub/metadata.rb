require 'rubygems'
require 'nokogiri'

module GEPUB
  # Holds data in /package/metadata 
  class Metadata
    include XMLUtil
    attr_reader :opf_version, :other_nodes

    # Holds one metadata with refine meta elements.
    class Meta
      attr_accessor :content
      attr_reader :name
      def initialize(name, content, attributes= {}, refiners = {})
        @name = name
        @content = content
        @attributes = attributes
        @refiners = refiners
      end

      def [](x)
        @attributes[x]
      end

      def []=(x,y)
        @attributes[x] = y
      end

      def refiner(name)
        return @refiners[name] 
      end

      def first_refiner(name)
        refiner = @refiners[name]
        if refiner.nil? || refiner.size == 0
          nil
        else
          refiner[0]
        end
      end
      
      def add_refiner(refiner)
        raise 'refiner element need property attribute' if refiner['property'].nil? 
        (@refiners[refiner['property']] ||= []) << refiner
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
              [(v.first_refiner('display-seq') || Meta.new(nil, 2 ** (0.size * 8 - 2) - 1)).content.to_i, i += 1]
            }              
          }

          @xml.xpath("#{prefix(OPF_NS)}:meta[not(@refines) and @property]", @namespaces).each {
            |node|
            @meta[node['property']] = create_meta(node)
          }

          @other_nodes = parse_opf2_meta
        }
      }
    end
    
    def initialize(opf_version = '3.0')
      @content_nodes = {}
      @meta = {}
      @other_nodes = []
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
      define_method('list_' + node) { @content_nodes[node] } 

      define_method(node) {
        if !@content_nodes[node].nil? && @content_nodes[node].size > 0
          @content_nodes[node][0].content
        end
      }
    }


    private
    def parse_node(ns, node)
      @xml.xpath("#{prefix(ns)}:#{node}", @namespaces).map {
        |node|
        create_meta(node)
      }
    end

    def create_meta(node)
      Meta.new(node.name, node.content, node.attributes, collect_refiners(node['id']))
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
