module GEPUB
	class Metadata
		def add_metadata(name, content, id: nil, itemclass: Meta,
		title_type: nil,identifier_type: nil,display_seq: nil,file_as: nil,group_position: nil,role: nil,
		lang: nil,
		alternates: {}
		)
			meta = add_metadata_internal(name, content, id: id, itemclass: itemclass)
      [{ value: title_type, name: 'title-type'},{ value: identifier_type, name: 'identifier-type'},{ value: display_seq, name: 'display-seq'},{ value: file_as, name: 'file-as'},{ value: group_position, name: 'group-position'},{ value: role, name: 'role'}].each do |refiner|
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
