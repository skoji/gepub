module GEPUB
  class Item
    attr_accessor :itemid, :href, :mediatype, :content

    def initialize(itemid, href, mediatype = nil)
      @itemid = itemid
      @href = href
      @mediatype = mediatype || guess_mediatype
    end

    def add_content(io)
      io.binmode
      @content = io.read
      self
    end
    
    def guess_mediatype
      case File.extname(@href)
      when /.(html|xhtml)/i
        'application/xhtml+xml'
      when /.css/i
        'text/css'
      when /.js/i
        'text/javascript'
      when /.(jpg|jpeg)/i
        'image/jpeg'
      when /.png/i
        'image/png'
      when /.gif/i
        'image/gif'
      when /.svg/i
        'image/svg+xml'
      when /.opf/i
        'application/oebps-package+xml'
      when /.ncx/i
        'application/x-dtbncx+xml'
      end
    end
  end
end  
