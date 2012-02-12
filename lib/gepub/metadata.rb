require 'rubygems'
require 'nokogiri'

module GEPUB
  # Holds data in 
  class Metadata
    include XMLUtil
    attr_reader :opf_version
    def self.parse(metadata_xml, opf_version = '3.0')
      Metadata.new(opf_version) {
        |metadata|
        metadata.instance_eval {
          @xml = metadata_xml
          @namespaces = @xml.root.namespaces
        }
      }
    end
    
    def initialize(opf_version = '3.0')
      @opf_version = opf_version
      @namespaces = { 'xmlns:dc' =>  DC_NS }
      @namespaces['xmlns:opf'] = OPF_NS if opf_version.to_f < 3.0 
      yield self if block_given?
    end
  end
end
