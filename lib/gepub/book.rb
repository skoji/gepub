# -*- coding: utf-8 -*-
require 'rubygems'
require 'xml/libxml'
require 'zip/zip'
require 'fileutils'


module GEPUB
  class Book
    attr_accessor :spine, :locale

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

    def add_nav(item, text)
      @toc.push({ :item => item, :text => text})
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
      result = XML::Document.new
      result.root = XML::Node.new('package')
      package = result.root
      XML::Namespace.new(package, nil, 'http://www.idpf.org/2007/opf')
      package['version'] = '2.0'
      package['unique-identifier'] = 'BookID'


      package << metadataelem = XML::Node.new('metadata')
      XML::Namespace.new(metadataelem, 'opf', 'http://www.idpf.org/2007/opf')
      XML::Namespace.new(metadataelem, 'dc', "http://purl.org/dc/elements/1.1/")

      metadataelem << XML::Node.new('dc:language', @locale)

      @metadata.each { | k, v |
        if (k == :cover)
          metadataelem << node = XML::Node.new("meta")
          node['name'] = 'cover'
          node['content'] = v
        elsif (k == :identifier)
          v.each {
            |id|
            metadataelem << node = XML::Node.new("dc:#{k}",id[:identifier])
            if (id[:main_id])
              node['id'] = 'BookID'
            end
            node['opf:scheme'] = id[:scheme]
          }
        elsif (k == :gepub_version)
          metadataelem << node = XML::Node.new("meta")
          node['name'] = 'gepub version'
          node['content'] = v
        else
          metadataelem << node = XML::Node.new("dc:#{k}",v)
        end
      }

      package << manifestelem = XML::Node.new('manifest')
      @manifest.each {
        |item|
        manifestelem << node = XML::Node.new("item")
        node['id'] = "#{item.itemid}"
        node['href'] = "#{item.href}"
        node['media-type'] = "#{item.mediatype}" 
      }
      
      package << spineelem = XML::Node.new('spine')
      spineelem['toc'] = 'ncx'

      @spine.each {
        |v|
        spineelem << node = XML::Node.new('itemref')
        node['idref'] = "#{v.itemid}"
      }

      result.to_s

    end

    def ncx_xml
      result = XML::Document.new
      result.root = XML::Node.new('ncx')
      root = result.root
      XML::Namespace.new(root, nil, "http://www.daisy.org/z3986/2005/ncx/")
      root['version'] = "2005-1"
      root << head = XML::Node.new('head')
      head << uid = XML::Node.new('meta')
      uid['name'] = 'dtb:uid'
      uid['content'] = "#{@main_identifier}"

      head << depth = XML::Node.new('meta')
      depth['name'] = 'dtb:depth'
      depth['content'] = '1'

      head << totalPageCount = XML::Node.new('meta')
      totalPageCount['name'] = 'dtb:totalPageCount'
      totalPageCount['content'] = '0'

      head << maxPageNumber = XML::Node.new('meta')
      maxPageNumber['name'] = 'dtb:maxPageNumber'
      maxPageNumber['content'] = '0'


      root << docTitle = XML::Node.new('docTitle')
      docTitle << XML::Node.new('text', "#{@metadata[:title]}")
      
      root << nav_map = XML::Node.new('navMap')
      count = 1
      @toc.each {
        |x|
        nav_point = XML::Node.new('navPoint')
        nav_point['id'] = "#{x[:item].itemid}"
        nav_point['playOrder'] = "#{count}"
        
        nav_label = XML::Node.new('navLabel')
        nav_label << XML::Node.new('text', "#{x[:text]}")
        
        nav_content = XML::Node.new('content')
        nav_content['src'] = "#{x[:item].href}"
        count = count + 1

        nav_map << nav_point
        nav_point << nav_label
        nav_point << nav_content
      }
      result.to_s
    end
  end
end
