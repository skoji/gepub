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

require_relative '../lib/gepub/dsl_util.rb'
require_relative '../lib/gepub/meta.rb'

refiners = GEPUB::Meta::REFINERS.map do |refiner|
	refiner.sub('-', '_')
end

refiners_arguments_string = refiners.map { |refiner| "#{refiner}: nil" }.join(',')
refiners_string = "[" + GEPUB::Meta::REFINERS.map { |refiner| "{ value: #{refiner.sub('-', '_')}, name: '#{refiner}'}" }.join(",") + "]"

File.write(File.join(File.dirname(__FILE__), "../lib/gepub/metadata_add.rb"), <<EOF)
module GEPUB
	class Metadata
		def add_metadata(name, content, id: nil, itemclass: Meta,
		#{refiners_arguments_string},
		lang: nil,
		alternates: {}
		)
			meta = add_metadata_internal(name, content, id: id, itemclass: itemclass)
      #{refiners_string}.each do |refiner|
				if refiner[:value]
				  meta.refine(refiner[:name], refiner[:value])
				end
	    end	
			if lang
			  meta.lang = lang
			end
			if alternates
			  meta.add_alternates alternates
			end
      yield meta if block_given?
			meta
		end
	end
end
EOF
