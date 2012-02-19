# -*- coding: utf-8 -*-
require 'rubygems'
require 'nokogiri'
require 'zip/zip'
require 'fileutils'


module GEPUB
  class Book

    def initialize(path='OEBPS/package.opf', attributes = {})
      if File.extname(path) != '.opf'
        warn 'GEPUB::Book#new interface changed. you must supply path to package.opf as first argument. if you want to set title, use GEPUB::Book.title='
      end
      @package = Package.new(path, attributes)
      @toc = []
      yield book if block_given?
    end

    def add_nav(item, text, id = nil)
      @toc.push({ :item => item, :text => text, :id => id})      
    end


    def method_missing(name,*args)
      @package.send(name, *args)
    end
    
    def generate_epub(path_to_epub)
      if (@toc.size == 0)
        @toc << { :item => @package.spine.itemref_list[0] }
      end

      if version.to_f < 3.0 || @package.epub_backward_compat
        add_item('toc.ncx', StringIO.new(ncx_xml), 'ncx')
      end

      if version.to_f >=3.0
        @package.metadata.set_lastmodified
      end

      File.delete(path_to_epub) if File.exist?(path_to_epub)
      Zip::ZipOutputStream::open(path_to_epub) {
        |epub|
        epub.put_next_entry('mimetype', '', '', Zip::ZipEntry::STORED)
        epub << "application/epub+zip"
        epub.put_next_entry('META-INF/container.xml')
        epub << container_xml

        epub.put_next_entry(@package.path)
        epub << opf_xml

        @package.manifest.item_list.each {
          |k, item|
          epub.put_next_entry(@package.contents_prefix + item.href)
          epub << item.content
        }
      }
    end
    
    def container_xml
      <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="#{@package.path}" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
EOF
    end

    def ncx_xml
      builder = Nokogiri::XML::Builder.new {
        |xml|
        xml.ncx('xmlns' => 'http://www.daisy.org/z3986/2005/ncx/', 'version' => '2005-1') {
          xml.head {
            xml.meta('name' => 'dtb:uid', 'content' => "#{self.identifier}") 
            xml.meta('name' => 'dtb:depth', 'content' => '1')
            xml.meta('name' => 'dtb:totalPageCount','content' => '0')
            xml.meta('name' => 'dtb:maxPageNumber', 'content' => '0')
          }
          xml.docTitle {
            xml.text_ "#{@package.metadata.title}"
          }
          count = 1
          xml.navMap {
            @toc.each {
              |x|
              xml.navPoint('id' => "#{x[:item].itemid}", 'playOrder' => "#{count}") {
                xml.navLabel {
                  xml.text_  "#{x[:text]}"
                }
                if x[:id].nil?
                  xml.content('src' => "#{x[:item].href}")
                else
                  xml.content('src' => "#{x[:item].href}##{x[:id]}")
                end
              }
              count += 1
            }
          }
        }
      }
      builder.to_xml
    end

  end
end
