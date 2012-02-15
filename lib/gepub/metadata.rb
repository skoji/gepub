require 'rubygems'
require 'nokogiri'

module GEPUB
  # Holds data in /package/metadata 
  class Metadata
    include XMLUtil
    attr_reader :opf_version, :titles

    class Meta
      attr_accessor :content, :attributes
      def initialize(content, attributes= {}, refiners = {})
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
      def add_refiner(refiner)
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
          @titles = parse_title
        }
      }
    end
    
    def initialize(opf_version = '3.0')
      @opf_version = opf_version
      @namespaces = { 'xmlns:dc' =>  DC_NS }
      @namespaces['xmlns:opf'] = OPF_NS if @opf_version.to_f < 3.0 
      yield self if block_given?
    end

    def main_title
      @titles[0].content
    end

    private

    private

    def parse_title
      titles = []
      @xml.xpath("#{prefix(DC_NS)}:title", @namespaces).each {
        |title|
        titles << create_meta(title)
      }
      titles
    end

    def create_meta(node)
      Meta.new(node.content, node.attributes, collect_refiners(node['id']))
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

  end
end
