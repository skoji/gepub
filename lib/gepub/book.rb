# -*- coding: utf-8 -*-
require 'rubygems'
require 'nokogiri'
require 'zip/zip'
require 'fileutils'


module GEPUB
  class Book < Package

    def initialize(path='OEBPS/package.opf', attributes = {})
      if File.extname(path) != '.opf'
        warn 'GEPUB::Book#new interface changed. you must supply path to package.opf as first argument. if you want to set title, use GEPUB::Book.title='
      end
      super(path, attributes)
      yield book if block_given?
    end

    def generate_epub(path_to_epub)
      if (@toc.size == 0)
        @toc << { :item => @spine.itemref_list[0] }
      end

      if version.to_f < 3.0 || @epub_backword_compat
        add_item('toc.ncx', StringIO.new(ncx_xml), 'ncx')
      end

      if version.to_f >=3.0
        @metadata.set_lastmodified
      end

      File.delete(path_to_epub) if File.exist?(path_to_epub)
      Zip::ZipOutputStream::open(path_to_epub) {
        |epub|
        epub.put_next_entry('mimetype', '', '', Zip::ZipEntry::STORED)
        epub << "application/epub+zip"
        epub.put_next_entry('META-INF/container.xml')
        epub << container_xml

        epub.put_next_entry(@path)
        epub << opf_xml

        @manifest.item_list.each {
          |k, item|
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
    <rootfile full-path="#{@path}" media-type="application/oebps-package+xml"/>
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
      uid['content'] = "#{self.identifier}"

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
      docTitleText.content = "#{@metadata.title}"

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
