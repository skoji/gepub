module GEPUB
  #
  # Static Object to hold and operate with OEBPS data MIME types
  #

  class Mime
    
    # media types by file extension regexp seeds to mime types
    @@mime_types =  { 
      '(html|xhtml)' => 'application/xhtml+xml',
      'css' => 'text/css',
      'js' => 'text/javascript',
      '(jpg|jpeg)' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'svg' => 'image/svg+xml',
      'opf' => 'application/oebps-package+xml',
      'ncx' => 'application/x-dtbncx+xml',
      '(otf|ttf|ttc|eot)' => 'application/vnd.ms-opentype',
      'woff' => 'application/font-woff',
      'mp4' => 'video/mp4',
      'mp3' => 'audio/mpeg'
    }
    
    # return mime media types => mime types hash
    def self.mime_types
       @@mime_types
    end

    # add new mediatype to @@mediatypes
    def self.add_mimetype(mediatypes)
      mediatypes.each { |expr, mime| @@mime_types[expr] = mime if !@@mime_types[expr] }
    end

    #guess mediatype by mime type mask
    def self.guess_mediatype(href)
      @@mime_types.each { |ext, mime| return mime if File.extname(href) =~ /.#{ext}/i }
    end
    
  end
end