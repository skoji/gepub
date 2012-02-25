module GEPUB
  class Builder
    include BuilderMixin
    class MetaItem
      def initialize(item)
        @item = item
      end

      def apply_one_to_multi
        false
      end

      def alt(alternates = {})
        @item.add_alternates(alternates)
      end

      def file_as(name)
        @item.set_file_as(name)
      end

      def seq(num)
        @item.set_display_seq(num)
      end

      def group_position(num)
        @item.set_group_position(num)
      end

      def id(val)
        @item['id'] = val
      end
    end

    def initialize(attributes = {},  &block)
      @last_defined_item = nil
      @book = Book.new
      instance_eval &block
      # TODO check @book's consistency
      true
    end

    # define base methods.
    GEPUB::Metadata::CONTENT_NODE_LIST.each {
      |name|
      define_method(name) { |val| @last_defined_item = MetaItem.new(@book.send("add_#{name}".to_sym, val, nil)) }
    }

    GEPUB::TITLE_TYPE::TYPES.each {
      |type|
      case type
      when 'main'
        methodname = 'title'
      when 'short'
        methodname = 'short_title'
      when 'expanded'
        methodname = 'expandend_title'
      else
        methodname = type
      end
      define_method(methodname) { |val| @last_defined_item = MetaItem.new(@book.add_title(val, nil, type)) }
    }

    def collection(val, count = 1)
      @last_defined_item =
        MetaItem.new(@book.add_title(val, nil, GEPUB::TITLE_TYPE::COLLECTION).set_group_position(count.to_s))
    end

    def creator(val, role = 'aut')
      MetaItem.new(@book.add_creator(val, nil, role))
    end

    def creators(*vals)
      @last_defined_item = vals.map {
        |v|
        name = v
        role = 'aut'
        name,role = v[0], v[1] if Array === name
        MetaItem.new(@book.add_creator(name, nil, role))
      }
    end

    def contributors(*vals)
      @last_defined_item = vals.map {
        |v|
        name = v
        role = nil
        name,role = v[0], v[1] if Array === name
        MetaItem.new(@book.add_contributor(name, nil, role))
      }
    end

    def publishers(*vals)
      @last_defined_item = vals.map {
        |v|
        MetaItem.new(@book.add_publisher(v, nil))
      }
    end

    def unique_identifier(val, id = 'BookID', scheme = 'nil')
      @last_defined_item = MetaItem.new(@book.set_main_id(val, id, scheme))
    end
    
    def alts(alt_vals = {})
      raise "can't specify alts on single item" if ! Array === @last_defined_item
      @last_defined_item.each_with_index {
        |item, index| 
        item.alt Hash[*(alt_vals.map{|k,v| [k,v[index]]}.flatten)]
      }
    end
    
    def contributor(val, role = nil)
      MetaItem.new(@book.add_contributor(val, nil, role))
    end

    def generate_epub(path_to_epub)
      @book.generate_epub(path_to_epub)
    end

    def resources(attributes = {}, &block)
      ResourceBuilder.new(@book, attributes, &block)
    end
    
    def generate_epub_stream
      @book.generate_epub_stream
    end
  end
end
