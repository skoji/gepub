require 'rubygems'
require 'nokogiri'

module GEPUB
  # Holds data in opf file.
  class Package
    include XMLUtil
    attr_accessor :path, :metadata, :manifest, :spine, :epub_backward_compat

    class IDPool
      def initialize
        @pool = {}
        @counter = {}
      end

      def counter(prefix,suffix)
        @counter[prefix + '////' + suffix]
      end

      def set_counter(prefix,suffix,val)
        @counter[prefix + '////' + suffix] = val
      end
      
      def generate_key(param = {})
        while (true)
          prefix = param[:prefix] || ''
          suffix = param[:suffix] || ''
          count = [ param[:start] || 1, counter(prefix,suffix) || 1].max
          if param[:without_count]
            k = prefix + suffix
            count -= 1
            param[:without_count] = nil
          else
            k = prefix + count.to_s + suffix
          end
          if @pool[k].nil?
            set_counter(prefix,suffix, count + 1)
            return k
          end
          count += 1
        end

      end
      
      def [](k)
        @pool[k]
      end
      def []=(k,v)
        @pool[k] = v
      end
    end
    
    # parse OPF data. opf should be io or string object.
    def self.parse_opf(opf, path)
      Package.new(path) {
        |package|
        package.instance_eval {
          @path = path
          @xml = Nokogiri::XML::Document.parse(opf)
          @namespaces = @xml.root.namespaces
          @attributes = attr_to_hash(@xml.root.attributes)
          @metadata = Metadata.parse(@xml.at_xpath("//#{ns_prefix(OPF_NS)}:metadata"), @attributes['version'], @id_pool)
          @manifest = Manifest.parse(@xml.at_xpath("//#{ns_prefix(OPF_NS)}:manifest"), @attributes['version'], @id_pool)
          @spine = Spine.parse(@xml.at_xpath("//#{ns_prefix(OPF_NS)}:spine"), @attributes['version'], @id_pool)
        }
      }
    end

    def initialize(path, attributes={})
      if File.extname(path) != ''
        path = File.dirname(path) + '/package.opf'
      end
      @contents_prefix = File.dirname(path)
      @namespaces = {'xmlns' => OPF_NS }
      @attributes = attributes
      @attributes['version'] ||= '3.0'
      @id_pool = IDPool.new
      @metadata = Metadata.new(version)
      @manifest = Manifest.new(version)
      @spine = Spine.new(version)
      @epub_backword_compat = true
      yield self if block_given?
    end

    ['version', 'unique-identifier', 'xml:lang', 'dir', 'prefix', 'id'].each {
      |name|
      methodbase = name.gsub('-','_').sub('xml:lang', 'lang')
      define_method(methodbase + '=') { |val| @attributs[name] =  val }
      define_method('set_' + methodbase) { |val| @attributes[name] = val }        
      define_method(methodbase) { @attributes[name] }
    }

    def [](x)
      @attributes[x]
    end

    def []=(k,v)
      @attributes[k] = v
    end


    def identifier
      unique_identifier
    end
    
    def identifier=(identifier)
      set_main_id(identifier, nil, 'URL')
    end
    
    def set_main_id(identifier, id = nil, type = nil)
      unique_identifier = id || id_pool.generate_key(:prefix => 'BookId', :without_count => true)
      @metadata.add_identifier identifier, unique_identifier, type
    end
    
    def specify_cover(item)
      # ... not smart. should create old-meta on generating xml
      @metadata.add_oldstyle_meta(nil, { 'name' => 'cover', 'content' => item.id })
      item.add_properties 'cover-image'
    end

    def add_item(href, io = nil, id = nil, attributes = {})
      id ||= @id_pool.generate_key(:prefix=>'item', :suffix=>'_'+ File.basename(href,'.*'), :without_count => true)
      item = @manifest.add_item(id, href, nil, attributes)
      item.add_content(io) unless io.nil?
      spine.push(item) if @ordered
      yield item if block_given?
      item
    end

    def ordered
      raise 'call with block.' if !block_given?
      @ordered = true
      yield
      @ordered = nil
    end

    def add_ordered_item(href, io = nil, id = nil, attributes = {})
      raise 'do not call add_ordered_item within ordered block.' if @ordered
      item = add_item(href, io, id, attributes)
      spine.push(item)
      item
    end

    def add_nav(item, text, id = nil)
      @toc.push({ :item => item, :text => text, :id => id})      
    end


    def method_missing(name, *args) 
      CONTENT_NODE_LIST.each {
        |x|
        case name.to_s
        when x
        when "#{x}_list"
        when "set_#{x}"
        when "#{x}="
          return @metadata.send(name, *args)
        end
      }
      super
    end

    def author=(val)
      warn 'do not use this method. use #creator'
      @metadata.creator= val
    end

    

    def specify_cover_image(item)
      warn 'do not use this method. use Item#cover_image'
      item.cover_image
    end

    def locale=(val)
      warn 'do not use this method. use #lang='
      @attribute['lang'] = val
    end

    def locale 
      warn 'do not use this method. use #lang'
      lang
    end

    def epub_version=(val)
      warn 'do not use this method. use #version='
      @attribute['version'] = val
    end

    def epub_version
      warn 'do not use this method. use #version'
      version
    end

    def to_xml
      if version.to_f < 3.0 || @epub_backword_compat
        spine.toc  ||= 'ncx'
        if @metadata.oldstyle_meta.select {
          |meta|
          meta['name'] == 'cover'
          }.length == 0
          
          @manifest.item_list.each {
            |k, item|
            if item.properties && item.properties.member?('cover-image')
              @metadata.add_oldstyle_meta(nil, 'name' => 'cover', 'content' => item.id)
            end
          }
        end
      end
      builder = Nokogiri::XML::Builder.new {
        |xml|
        xml.package(@namespaces.merge(@attributes)) {
          @metadata.to_xml(xml)
          @manifest.to_xml(xml)
          @spine.to_xml(xml)
        }
      }
      builder.to_xml
    end

    def generate_epub(path_to_epub)
      if (@toc.size == 0)
        @toc << { :item => @spine.itemref_list[0] }
      end

      if version.to_f < 3.0 || @epub_backword_compat
        add_item('toc.ncx', StringIO.new(ncx_xml), 'ncx')
      end

      File.delete(path_to_epub) if File.exist?(path_to_epub)
      Zip::ZipOutputStream::open(path_to_epub) {
        |epub|
        epub.put_next_entry('mimetype', '', '', Zip::ZipEntry::STORED)
        epub << "application/epub+zip"
        epub.put_next_entry('META-INF/container.xml')
        epub << container_xml

        epub.put_next_entry(@contents_prefix + 'content.opf')
        epub << opf_xml

        # create items
        @manifest.each {
          |item|
          epub.put_next_entry(@contents_prefix + item.href)
          epub << item.content
        }
      }
    end
    
    def container_xml
      <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="#{@contents_prefix}content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
EOF
    end

    def ncx_xml
      ncx = Nokogiri::XML::Document.new
      ncx.root = root = Nokogiri::XML::Node.new('ncx', ncx)
      root.add_namespace(nil, "http://www.daisy.org/z3986/2005/ncx/")
      root['version'] = "2005-1"
      root << head = Nokogiri::XML::Node.new('head', ncx)
      head << uid = Nokogiri::XML::Node.new('meta', ncx)
      uid['name'] = 'dtb:uid'
      uid['content'] = "#{@main_identifier}"

      head << depth = Nokogiri::XML::Node.new('meta', ncx)
      depth['name'] = 'dtb:depth'
      depth['content'] = '1'

      head << totalPageCount = Nokogiri::XML::Node.new('meta', ncx)
      totalPageCount['name'] = 'dtb:totalPageCount'
      totalPageCount['content'] = '0'

      head << maxPageNumber = Nokogiri::XML::Node.new('meta', ncx)
      maxPageNumber['name'] = 'dtb:maxPageNumber'
      maxPageNumber['content'] = '0'

      root << docTitle = Nokogiri::XML::Node.new('docTitle', ncx)
      docTitle << docTitleText = Nokogiri::XML::Node.new('text', ncx)
      docTitleText.content = "#{@metadata[:title]}"

      root << nav_map = Nokogiri::XML::Node.new('navMap', ncx)
      count = 1
      @toc.each {
        |x|
        nav_point = Nokogiri::XML::Node.new('navPoint', ncx)
        nav_point['id'] = "#{x[:item].itemid}"
        nav_point['playOrder'] = "#{count}"
        
        nav_label = Nokogiri::XML::Node.new('navLabel', ncx)
        nav_label << navtxt = Nokogiri::XML::Node.new('text', ncx)
        navtxt.content = "#{x[:text]}"
        
        nav_content = Nokogiri::XML::Node.new('content', ncx)
        if x[:id].nil?
          nav_content['src'] = "#{x[:item].href}"
        else
          nav_content['src'] = "#{x[:item].href}##{x[:id]}"
        end
        
        count = count + 1
        nav_map << nav_point
        nav_point << nav_label
        nav_point << nav_content
      }
      ncx.to_s
    end

  end
end
