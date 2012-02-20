module GEPUB
  module XMLUtil
    OPF_NS = 'http://www.idpf.org/2007/opf'
    DC_NS = 'http://purl.org/dc/elements/1.1/'
    def ns_prefix(ns)
      prefix = raw_prefix(ns)
      prefix.nil? ? nil : prefix.sub(/^xmlns:/,'')
    end

    def raw_prefix(ns)
      @namespaces.key(ns)      
    end

    def attr_to_hash(nokogiri_attrs)
      attributes = {}
      nokogiri_attrs.each {
        |k,v|
        attributes[k] = v.to_s
      }
      if attributes['lang']
        attributes['xml:lang'] = attributes['lang'];
        attributes.delete('lang')
      end
      attributes
    end
  end
end
