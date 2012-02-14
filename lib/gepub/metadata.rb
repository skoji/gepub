require 'rubygems'
require 'nokogiri'

module GEPUB
  # Holds data in /package/metadata 
  class Metadata
    include XMLUtil
    attr_reader :opf_version

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
      @titles[0][:name]
    end

    private

    def parse_title
      titles = []
      @xml.xpath("#{prefix(DC_NS)}:title", @namespaces).each {
        |title|
        titles << { :name => title.content, :id => title['id'], :lang => title['lang'], :dir => title['dir'] }
      }
      titles
    end

  end
end
