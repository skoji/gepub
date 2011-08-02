# -*- coding: utf-8 -*-
require 'rubygems'
require 'nokogiri'
require 'zip/zip'
require 'fileutils'


module GEPUB
  class Book
    attr_accessor :spine, :locale, :epub_version, :epub_backword_compat

    def self.def_meta(name, key = nil)
      key ||= name
      define_method name.to_sym do
        instance_variable_get('@metadata')[key.to_sym]
      end
      define_method ( name.to_s + "=" ).to_sym do
        |v|
        instance_variable_get('@metadata')[key.to_sym] = v
      end
    end
    
    def initialize(title, contents_prefix="")
      @metadata = {}
      @metadata[:identifier] = []
      @metadata[:title] = title
      @metadata[:gepub_version] = '0.1'
      @manifest = []
      @spine = []
      @toc = []
      @contents_prefix = contents_prefix # may insert "OEBPS"
      @contents_prefix = @contents_prefix + "/" if contents_prefix != ""
      @itemcount = 0
      @locale = 'en'
      @epub_version = 2.1
      @epub_backword_compat = false
    end

    def_meta :title
    def_meta :author, :creator
    def_meta :contributor
    def_meta :publisher
    def_meta :date
    
    def identifier
      @main_identifier
    end

    def identifier=(id)
      @metadata[:identifier] << { :scheme => 'URL', :identifier => id, :main_id => true }
      @main_identifier = id
    end

    def setIdentifier(scheme, identfier)
      @metadata[:identifier] << { :scheme => scheme, :identifier => identifier }
    end

    def add_ref_to_item(href, itemid = nil)
      itemid ||= 'item' + @itemcount.to_s + "_" + File.basename(href, '.*')
      @itemcount = @itemcount + 1
      item = Item.new(itemid, href)
      @manifest << item
      item
    end

    def add_item(href, io, itemid = nil)
      add_ref_to_item(href, itemid).add_content(io)
    end

    def add_ordered_item(href, io, itemid = nil)
      item = add_item(href, io, itemid)
      @spine.push(item)
      item
    end

    def add_nav(item, text, id = nil)
      @toc.push({ :item => item, :text => text, :id => id})
    end

    def specify_cover_image(item)
      @metadata[:cover] = item.itemid
    end

    def cover_image_item
      @metadata[:cover]
    end

    def generate_epub(path_to_epub)
      if (@toc.size == 0)
        @toc << { :item => @spine[0], :text => " " }
      end

      add_item('toc.ncx', StringIO.new(ncx_xml), 'ncx')

      File.delete(path_to_epub) if File.exist?(path_to_epub)
      Zip::ZipOutputStream::open(path_to_epub) {
        |epub|

        # create metadata files
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

    def opf_xml
      opf = Nokogiri::XML::Document.new
      opf.root = package = Nokogiri::XML::Node.new('package', opf)
      package.add_namespace(nil, 'http://www.idpf.org/2007/opf')
      package['version'] = '2.0'
      package['unique-identifier'] = 'BookID'
      package << metadataelem = Nokogiri::XML::Node.new('metadata', opf)
      metadataelem.add_namespace('opf', 'http://www.idpf.org/2007/opf')
      metadataelem.add_namespace('dc', "http://purl.org/dc/elements/1.1/")
      metadataelem << lang = Nokogiri::XML::Node.new('dc:language', opf)
      lang.content = @locale
      @metadata.each { |k,v|
        if (k == :cover)
          metadataelem << node = Nokogiri::XML::Node.new("meta", opf)
          node['name'] = 'cover'
          node['content'] = v
        elsif (k == :identifier)
          v.each {
            |id|
            metadataelem << node = Nokogiri::XML::Node.new("dc:#{k}", opf)
            node.content = id[:identifier]
            if (id[:main_id])
              node['id'] = 'BookID'
            end
            node['opf:scheme'] = id[:scheme]
          }
        elsif (k == :gepub_version)
          metadataelem << node = Nokogiri::XML::Node.new("meta", opf)
          node['name'] = 'gepub version'
          node['content'] = v
        else
          metadataelem << node = Nokogiri::XML::Node.new("dc:#{k}",opf)
          node.content = v
        end
      }

      package << manifestelem = Nokogiri::XML::Node.new('manifest', opf)
      @manifest.each {
        |item|
        manifestelem << node = Nokogiri::XML::Node.new("item", opf)
        node['id'] = "#{item.itemid}"
        node['href'] = "#{item.href}"
        node['media-type'] = "#{item.mediatype}" 
      }

      package << spineelem = Nokogiri::XML::Node.new('spine', opf)
      spineelem['toc'] = 'ncx'

      @spine.each {
        |v|
        spineelem << node = Nokogiri::XML::Node.new('itemref', opf)
        node['idref'] = "#{v.itemid}"
      }
      opf.to_s
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
