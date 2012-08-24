module GEPUB
  class Rendition
    class NilContent
      def self.content
        nil
      end
    end
    
    def initialize()
      @default_layout = 'reflowable'
      @default_orientation = 'auto'
      @default_spread = 'auto'
      @layout = NilContent
      @orientation = NilContent
      @spread = NilContent
    end

    def set_metadata(metadata)
      @metadata = metadata
      @metadata.meta_list.each {
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
    
    def value_map
      { 'layout' => layout, 'orientation' => orientation, 'spread' => spread }
    end
  end
end
