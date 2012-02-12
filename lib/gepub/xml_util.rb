module GEPUB
  module XMLUtil
    OPF_NS = 'http://www.idpf.org/2007/opf'
    DC_NS = 'http://purl.org/dc/elements/1.1/'
    def prefix(ns)
      @namespaces_rev ||= @namespaces.invert
      @namespaces_rev[ns]
    end
    def dc
      prefix DC_NS
    end
    def opf
      prefix OPF
    end

  end
end
