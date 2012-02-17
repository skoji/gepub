module GEPUB
  module XMLUtil
    OPF_NS = 'http://www.idpf.org/2007/opf'
    DC_NS = 'http://purl.org/dc/elements/1.1/'
    def prefix(ns)
      prefix = raw_prefix(ns)
      prefix.nil? ? nil : prefix.sub(/^xmlns:/,'') 
    end
    def raw_prefix(ns)
      (@namespaces_rev ||= @namespaces.invert)[ns]      
    end
  end
end
