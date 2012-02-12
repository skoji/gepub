module GEPUB
  module XMLUtil
    OPF_NS = 'http://www.idpf.org/2007/opf'
    DC_NS = 'http://purl.org/dc/elements/1.1/'
    def prefix(ns)
      @namespaces_rev ||= @namespaces.invert
      @namespaces_rev[ns]
    end
  end
end
