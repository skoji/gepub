require 'rubygems'
require 'nokogiri'
module GEPUB
  class Bindings
    include XMLUtil
    class MediaType
      attr_accessor :handler, :media_type
      def initialize(handler, media_type)
        @handler = handler
        @media_type = media_type
      end
      def to_xml(builder)
        builder.mediaType({'handler' => @handler, 'media-type' => @media_type})
      end
    end

    def initialize
      @media_types = []
      @handler_by_media_type = {}
      yield self if block_given?
    end

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

    def media_types
      return @media_types.dup
    end

    def handler_by_media_type
      return @handler_by_media_type.dup
    end

    def add(id, media_type)
      @media_types << MediaType.new(id, media_type)
      @handler_by_media_type[media_type] =  id
    end

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
