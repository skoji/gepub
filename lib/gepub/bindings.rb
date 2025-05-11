require 'rubygems'
require 'nokogiri'
module GEPUB
  class Bindings
    include XMLUtil
    include InspectMixin

    class MediaType
      attr_accessor :handler, :media_type
      # @rbs (String, String) -> void
      def initialize(handler, media_type)
        @handler = handler
        @media_type = media_type
      end
      # @rbs (Nokogiri::XML::Builder) -> Nokogiri::XML::Builder::NodeBuilder
      def to_xml(builder)
        builder.mediaType({'handler' => @handler, 'media-type' => @media_type})
      end
    end

    # @rbs () -> void
    def initialize
      @media_types = []
      @handler_by_media_type = {}
      yield self if block_given?
    end

    # @rbs (Nokogiri::XML::Element?) -> GEPUB::Bindings
    def self.parse(bindings_xml)
      Bindings.new {
        |bindings|
        bindings.instance_eval {
          if !bindings_xml.nil?
            @xml = bindings_xml
            @namespaces = @xml.namespaces
            @attributes = attr_to_hash(@xml.attributes)
            @xml.xpath("//#{ns_prefix(OPF_NS)}:bindings/#{ns_prefix(OPF_NS)}:mediaType", @namespaces).map {
              |mediaType|
              @media_types <<  MediaType.new(mediaType['handler'], mediaType['media-type'])
              @handler_by_media_type[mediaType['media-type']] = mediaType['handler']
            }
          end
        }
      }
    end

    # @rbs () -> Array[untyped]
    def media_types
      return @media_types.dup
    end

    # @rbs () -> Hash[untyped, untyped]
    def handler_by_media_type
      return @handler_by_media_type.dup
    end

    # @rbs (String, String) -> void
    def add(id, media_type)
      @media_types << MediaType.new(id, media_type)
      @handler_by_media_type[media_type] =  id
    end

    # @rbs (Nokogiri::XML::Builder) -> Nokogiri::XML::Builder::NodeBuilder?
    def to_xml(builder)
      if (media_types.size > 0)
        builder.bindings {
          @media_types.each {
            |mediaType|
            mediaType.to_xml(builder)
          }
        }
      end
    end
  end
end
