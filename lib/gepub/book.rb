# -*- coding: utf-8 -*-
require 'rubygems'
require 'nokogiri'
require 'zip/zip'
require 'fileutils'


module GEPUB
  class Book
    MIMETYPE='mimetype'
    MIMETYPE_CONTENTS='application/epub+zip'
    CONTAINER='META-INF/container.xml'
    ROOTFILE_PATTERN=/^.+\.opf$/
    CONTAINER_NS='urn:oasis:names:tc:opendocument:xmlns:container'

    def self.rootfile_from_container(rootfile)
      doc = Nokogiri::XML::Document.parse(rootfile)
      ns = doc.root.namespaces
      defaultns = ns.select{ |name, value| value == CONTAINER_NS }.keys[0]
      doc.css("#{defaultns}|rootfiles > #{defaultns}|rootfile")[0]['full-path']
    end

    def self.parse(io)
      files = {}
      package = nil
      package_path = nil
      Zip::ZipInputStream::open_buffer(io) {
        |zis|
        while entry = zis.get_next_entry
          if !entry.directory?
            files[entry.name] = zis.read
            case entry.name
            when MIMETYPE then
              files[MIMETYPE] = nil 
            when CONTAINER then
              package_path = rootfile_from_container(files[entry.name])
              files[CONTAINER] = nil
            when ROOTFILE_PATTERN then
              package = Package.parse_opf(files[entry.name], entry.name)
            end
          end
        end
        if package_path != package.path
          warn 'inconsistend EPUB file: container says opf is #{package_path}, but actually #{package.path}'
        end
        files.each {
          |k, content|
          item = package.manifest.item_by_href(k.sub(/^#{package.contents_prefix}/,''))
          if !item.nil?
            files[k] = nil
            item.add_raw_content(content)
          end
        }
        book = Book.new(package.path)
        book.instance_eval { @package = package; @stray_files = files }
        book
      }
    end
    
    def initialize(path='OEBPS/package.opf', attributes = {})
      if File.extname(path) != '.opf'
        warn 'GEPUB::Book#new interface changed. You must supply path to package.opf as first argument. If you want to set title, please use GEPUB::Book#title='
      end
      @package = Package.new(path, attributes)
      @toc = []
      yield book if block_given?
    end

    def add_nav(item, text, id = nil)
      warn 'add_nav is deprecated: please use Item#toc_text'
      @toc.push({ :item => item, :text => text, :id => id})      
    end

    def add_item(href, io = nil, id = nil, attributes = {})
      item = @package.add_item(href,io,id,attributes)
      toc = @toc
      (class << item;self;end).send(:define_method, :toc_text,
                                    Proc.new { |text|
                                      toc.push(:item => item, :text => text, :id => nil)
                                      item
                                    })
      yield item if block_given?
      item
    end

    def add_ordered_item(href, io = nil, id = nil, attributes = {})
      item = @package.add_ordered_item(href,io,id,attributes)
      toc = @toc
      (class << item;self;end).send(:define_method, :toc_text,
                                    Proc.new { |text|
                                      toc.push(:item => item, :text => text, :id => nil)
                                      item
                                    })
      yield item if block_given?
      item
    end
    
    def method_missing(name,*args)
      @package.send(name, *args)
    end
    
    def ordered(&block)
      @package.ordered(&block)
    end

    def generate_epub(path_to_epub)

      if version.to_f < 3.0 || @package.epub_backward_compat
        if @package.manifest.item_list.select {
          |x,item|
          item.media_type == 'application/x-dtbncx+xml'
        }.size == 0
          if (@toc.size == 0)
            @toc << { :item => @package.manifest.item_list[@package.spine.itemref_list[0].idref] }
          end
          add_item('toc.ncx', StringIO.new(ncx_xml), 'ncx')
        end
      end

      if version.to_f >=3.0
        @package.metadata.set_lastmodified
        if @package.manifest.item_list.select {
          |href, item|
          (item.properties||[]).member? 'nav'
          }.size == 0
          generate_nav_doc
        end
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

    def generate_nav_doc(title = 'Table of Contents')
      add_item('nav.html', StringIO.new(nav_doc(title)), 'nav').add_property('nav')
    end

    def nav_doc(title = 'Table of Contents')
      builder = Nokogiri::XML::Builder.new {
        |doc|
        doc.html('xmlns' => "http://www.w3.org/1999/xhtml",'xmlns:epub' => "http://www.idpf.org/2007/ops") {
          doc.head { doc.text ' ' }
          doc.body {
            doc.nav('epub:type' => 'toc', 'id' => 'toc') {
              doc.h1 "#{title}"
              doc.ol {
                @toc.each {
                  |x|
                  doc.li {
                    doc.a({'href' => x[:item].href} ,x[:text])
                  }
                }
              }
            }
          }
        }
      }
      builder.to_xml
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
