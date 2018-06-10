module GEPUB
  class Book
    # add an item(i.e. html, images, audios, etc)  to Book.
    # the added item will be referenced by the first argument in the EPUB container.
    def add_item(href, deprecated_content = nil, deprecated_id = nil, deprecated_attributes = nil, content: nil, 
                 id: nil,media_type: nil,fallback: nil,properties: nil,media_overlay: nil,toc_text: nil,
                 attributes: {})
      content, id, attributes = handle_deprecated_add_item_arguments(deprecated_content, deprecated_id, deprecated_attributes, content, id, attributes)
      add_item_internal(href, content: content, id: id, attributes: attributes)
    end

    # same as add_item, but the item will be added to spine of the EPUB.
    def add_ordered_item(href, deprecated_content = nil, deprecated_id = nil, deprecated_attributes = nil,  content:nil, id: nil, attributes: {})
      content, id, attributes = handle_deprecated_add_item_arguments(deprecated_content, deprecated_id, deprecated_attributes, content, id, attributes)
      add_ordered_item_internal(href, content: content, id: id, attributes: attributes)
    end
  end
end
