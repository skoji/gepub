module GEPUB
  class Rendition
    class NilContent
      def self.content
        nil
      end
    end
    
    def initialize(default = {})
      @default_layout = default['layout'] || 'reflowable'
      @default_orientation = default['orientation'] || 'auto'
      @default_spread = default['spread'] || 'auto'
      @layout = NilContent
      @orientation = NilContent
      @spread = NilContent
    end

    def read_from_metadata(metadata)
      metadata.meta_list.each {
        |metanode|
        case metanode['property']
        when 'rendition:layout'
          @layout = metanode
        when 'rendition:orientation'          
          @orientation = metanode
        when 'rendition:spread'
          @spread = metanode
        end
      }
    end

    def layout
      @layout.content || @default_layout
    end

    def orientation
      @orientation.content || @default_orientation
    end

    def spread
      @spread.content || @default_spread
    end
    
  end
end
