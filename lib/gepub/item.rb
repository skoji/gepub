module GEPUB
  class Item
    attr_accessor :content
    def self.create(parent, attributes = {})
      Item.new(attributes['id'], attributes['href'], attributes['media-type'], parent,
               attributes.reject { |k,v| ['id','href','media-type'].member?(k) })
    end

    def initialize(itemid, itemhref, itemmediatype = nil, parent = nil, attributes = {})
      if attributes['properties'].class == String
        attributes['properties'] = attributes['properties'].split(' ')
      end
      @attributes = {'id' => itemid, 'href' => itemhref, 'media-type' => itemmediatype}.merge(attributes)
      @attributes['media-type'] =  guess_mediatype if media_type.nil?
      @parent = parent
      @parent.register_item(self) unless @parent.nil?
      self
    end

    ['id', 'href', 'media-type', 'fallback', 'properties', 'media-overlay'].each { |name|
      methodbase = name.sub('-','_')
      define_method(methodbase + '=') { |val| @attributes[name] = val }
      define_method('set_' + methodbase) { |val| @attributes[name] = val }
      define_method(methodbase) { @attributes[name] }
    }

    def itemid
      id
    end

    def mediatype
      media_type
    end
    
    def [](x)
      @attributes[x]
    end

    def []=(x,y)
      @attributes[x] = y
    end
    
    def add_property(property)
      (@attributes['properties'] ||=[]) << property
      self
    end

    def cover_image
      add_property('cover-image')
    end
    
    def add_content(io)
      io.binmode
      @content = io.read
      self
    end

    def to_xml(builder)
      attr = @attributes.dup
      if !attr['properties'].nil?
        attr['properties'] = attr['properties'].join(' ')
      end
      builder.item(attr)
    end

    def guess_mediatype
      case File.extname(href)
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
      when /.(otf|ttf|ttc)/i
        'application/vnd.ms-opentype'
      when /.woff/i
        'application/font-woff'
      end
    end
  end
end  
