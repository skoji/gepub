module GEPUB
  class Item
    attr_accessor :id, :href, :mediatype, :content

    def initialize(id, href, mediatype = nil)
      @id = id
      @href = href
      @mediatype = mediatype || guess_mediatype
    end

    def add_content(io)
      @content = io
      self
    end
    
    def guess_mediatype
      case File.extname(@href)
      when /.(html|xhtml)/i
        'application/xhtml+xml'
      when /.css/i
        'text/css'
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
