module GEPUB
  #
  # an Object to hold metadata and content of item in manifest.
  #
  # following methods are created dynamically.
  # #id, #id=, #set_id, #href, #href=, #set_href, #media_type, #media_type=, #set_media_type,
  # #fallback, #fallback=, #set_fallback, #media_overlay, #media_overlay=, #set_media_overlay
  class Item
    include InspectMixin

    attr_accessor :content
    def self.create(parent, attributes = {})
      Item.new(attributes['id'], attributes['href'], attributes['media-type'], parent,
               attributes.reject { |k,_v| ['id','href','media-type'].member?(k) })
    end

    #
    # create Item.
    # 
    # if mediatype is not specified, it will be guessed from extension name.
    # Item can't guess media type for videos and  audios, so you should specify one.
    # 
    def initialize(itemid, itemhref, itemmediatype = nil, parent = nil, attributes = {})
      if attributes['properties'].class == String
        attributes['properties'] = attributes['properties'].split(' ')
      end
      @attributes = {'id' => itemid, 'href' => itemhref, 'media-type' => itemmediatype}.merge(attributes)
      @attributes['media-type'] = GEPUB::Mime.guess_mediatype(itemhref) if media_type.nil?
      @parent = parent
      @parent.register_item(self) unless @parent.nil?
      self
    end

    ATTRIBUTES = ['id', 'href', 'media-type', 'fallback', 'properties', 'media-overlay'].each { |name|
      methodbase = name.sub('-','_')
      define_method(methodbase + '=') { |val| @attributes[name] = val }
      define_method('set_' + methodbase) { |val| @attributes[name] = val; self }
      define_method(methodbase) { @attributes[name] }
    }

    # get item's id
    def itemid
      id
    end

    # get mediatype of the item.
    def mediatype
      media_type
    end

    # get +attribute+
    def [](attribute)
      @attributes[attribute]
    end

    # set +attribute+
    def []=(attribute, value)
      @attributes[attribute] = value
    end

    # add value to properties attribute.
    def add_property(property)
      (@attributes['properties'] ||=[]) << property
      self
    end

    # set 'cover-image' property to the Item.
    # On generating EPUB, EPUB2-style cover image meta item will be added.
    def cover_image
      add_property('cover-image')
    end

    # set 'nav' property to the Item.
    def nav
      add_property('nav')
    end

    # set toc text to the item
    def toc_text text
      toc.push(:item => self, :text => text, :id => nil)
      self
    end

    # set toc text with id to the item
    def toc_text_with_id text, toc_id
      toc.push(:item => self, :text => text, :id => toc_id)
      self
    end

    # set bindings: item is a handler for media_type
    def is_handler_of media_type
      bindings.add(self.id, media_type)
      self
    end

    def landmark(type:, title:, id: nil)
      landmarks.push(:type => type, :title => title, :item => self, :id => id)
      self
    end

    # guess and set content property from contents.
    def guess_content_property
      if File.extname(self.href) =~ /.x?html/ && @attributes['media-type'] === 'application/xhtml+xml'
        @attributes['properties'] ||= []
        parsed = Nokogiri::XML::Document.parse(@content)
        return unless parsed.root.node_name === "html"
        ns_prefix =  parsed.namespaces.invert['http://www.w3.org/1999/xhtml']
        if ns_prefix.nil?
          prefix = ''
        else
          prefix = "#{ns_prefix}:"
        end
        images = parsed.xpath("//#{prefix}img[starts-with(@src,'http')]")
        videos = parsed.xpath("//#{prefix}video[starts-with(@src,'http')]") + parsed.xpath("//#{prefix}video/#{prefix}source[starts-with(@src,'http')]")
        audios = parsed.xpath("//#{prefix}audio[starts-with(@src,'http')]") + parsed.xpath("//#{prefix}audio/#{prefix}source[starts-with(@src,'http')]")
        if images.size > 0 || videos.size > 0 || audios.size > 0
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
        scripts = parsed.xpath("//#{prefix}script") + parsed.xpath("//#{prefix}form")
        if scripts.size > 0
          self.add_property('scripted')
        end
      end
    end

    # add content data to the item.
    def add_raw_content(data)
      @content = data
      if File.extname(self.href) =~ /x?html$/
        @content.force_encoding('utf-8')
      end
      guess_content_property
      self
    end

    # add content from io or file to the item
    def add_content(io_or_filename)
      if io_or_filename.class == String
        File.open(io_or_filename, mode='r') do |f|
          add_content_io f
        end
      else
        add_content_io io_or_filename
      end
      self
    end

    def add_content_io(io)
      io.binmode
      @content = io.read
      if File.extname(self.href) =~ /x?html$/
        @content.force_encoding('utf-8')
      end
      guess_content_property
      self
    end

    # generate xml to supplied Nokogiri builder.
    def to_xml(builder, opf_version = '3.0')
      attr = @attributes.dup
      if opf_version.to_f < 3.0
        attr.reject!{ |k,_v| k == 'properties' }
      end
      if !attr['properties'].nil?
        attr['properties'] = attr['properties'].uniq.join(' ')
        if attr['properties'].size == 0
          attr.delete 'properties'
        end
      end
      builder.item(attr)
    end
  end
end
