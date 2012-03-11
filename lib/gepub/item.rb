module GEPUB
  #
  # an Object to hold metadata and content of item in manifest.
  #
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
      @content_callback = []
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

    def nav
      add_property('nav')
    end

    def check_content_property
      if File.extname(self.href) =~ /.x?html/
        @attributes['properties'] = (@attributes['properties'] || []).reject {
          |x| x == 'svg' || x == 'mathml' || x == 'switch' || x == 'remote-resources'
        }
        parsed = Nokogiri::XML::Document.parse(@content)
        ns_prefix =  parsed.namespaces.invert['http://www.w3.org/1999/xhtml']
        if ns_prefix.nil?
          prefix = ''
        else
          prefix = "#{ns_prefix}:"
        end
        videos = parsed.xpath("//#{prefix}video[starts-with(@src,'http')]")
        audios = parsed.xpath("//#{prefix}audio[starts-with(@src,'http')]")
        if videos.size > 0 || audios.size > 0
          self.add_property('remote-resources')
        end
        if parsed.xpath("//p:math", { 'p' => 'http://www.w3.org/1998/Math/MathML' }).size > 0
          self.add_property('mathml')
        end
        if parsed.xpath("//s:svg", { 's' => 'http://www.w3.org/2000/svg' }).size > 0
          self.add_property('svg')
        end
        if parsed.xpath("//epub:switch", { 'epub' => 'http://www.idpf.org/2007/ops' }).size > 0
          self.add_property('switch')
        end
      end
    end

    def add_raw_content(data)
      @content = data
      check_content_property
    end

    def push_content_callback(&block)
      @content_callback << block
    end

    def add_content(io_or_filename)
      io = io_or_filename
      if io_or_filename.class == String
        io = File.new(io_or_filename)
      end
      io.binmode
      @content = io.read
      check_content_property
      self
    end

    def to_xml(builder, opf_version = '3.0')
      attr = @attributes.dup
      if opf_version.to_f < 3.0
        attr.reject!{ |k,v| k == 'properties' }
      end
      if !attr['properties'].nil?
        attr['properties'] = attr['properties'].join(' ')
        if attr['properties'].size == 0
          attr.delete 'properties'
        end
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
