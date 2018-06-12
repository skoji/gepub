require_relative '../lib/gepub/item.rb'
attrs = GEPUB::Item::ATTRIBUTES.select do |attr|
  attr != 'href'
end.map do |attr|
  attr.sub('-', '_')
end
attrs << "toc_text" 
attrs_arguments_string = attrs.map { |attr| "#{attr}: nil" }.join(',')
attrs_internal_string = "{ " + attrs.map { |attr| "#{attr}: #{attr}"}.join(',') + " }"
File.write(File.join(File.dirname(__FILE__), "../lib/gepub/book_add_item.rb"), <<EOF)
module GEPUB
  class Book
    # add an item(i.e. html, images, audios, etc)  to Book.
    # the added item will be referenced by the first argument in the EPUB container.
    def add_item(href, deprecated_content = nil, deprecated_id = nil, deprecated_attributes = nil, content: nil, 
                 #{attrs_arguments_string},
                 attributes: {})
      content, id, attributes = handle_deprecated_add_item_arguments(deprecated_content, deprecated_id, deprecated_attributes, content, id, attributes)
      add_item_internal(href, content: content, item_attributes: #{attrs_internal_string}, attributes: attributes, ordered: false)
    end

    # same as add_item, but the item will be added to spine of the EPUB.
    def add_ordered_item(href, deprecated_content = nil, deprecated_id = nil, deprecated_attributes = nil,  content:nil,
                         #{attrs_arguments_string},
                         attributes: {})
      content, id, attributes = handle_deprecated_add_item_arguments(deprecated_content, deprecated_id, deprecated_attributes, content, id, attributes)
      add_item_internal(href, content: content, item_attributes: #{attrs_internal_string}, attributes: attributes, ordered: true)
    end
  end
end
EOF
