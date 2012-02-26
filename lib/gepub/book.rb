# -*- coding: utf-8 -*-
require 'rubygems'
require 'nokogiri'
require 'zip/zip'
require 'fileutils'

# = GEPUB 
# Author:: KOJIMA Satoshi
# namespace for gepub library.
# GEPUB::Book for parsing/generating, GEPUB::Builder for generating.
# GEPUB::Item holds data of resources like xhtml text, css, scripts, images, videos, etc.
# GEPUB::Meta holds metadata(title, creator, publisher, etc.) with its information (alternate script, display sequence, etc.)

module GEPUB
  # Book is the basic class to hold data in EPUB files.
  # 
  # It can generate and parse EPUB2/EPUB3 files. For generating a new EPUB file,
  # consider to use GEPUB::Builder. Builder is specialized for generating EPUB, 
  # very easy to use and can handle almost every metadata of EPUB3.
  # 
  # Book delegates many methods to objects in other class, so you can't find
  # them in Book#methods or in ri/rdoc documentation. Their description is below.
  #
  # == \Package Attributes
  # === Book#version (delegated to Package#version)
  # returns OPF version.
  # === Book#version=, Book#set_version (delegated to Package#version=)
  # set OPF version
  # === Book#unique_identifier (delegated to Package#unique_identifier)
  # return unique_identifier ID value. identifier itself can be get by Book#identifier
  # == \Metadata
  # \Metadata items(title, creator, publisher, etc) are GEPUB::Meta objects.
  # === Book#identifier (delegated to Package#identifier)
  # return GEPUB::Meta object of unique identifier.
  # === Book#identifier=(identifier)   (delegated to Package#identifier=)
  # set identifier (i.e. url, uuid, ISBN) as unique-identifier of EPUB.
  # === Book#set_main_id(identifier, id = nil, type = nil)   (delegated to Package#set_main_id)
  # same as identifier=, but can specify id (in the opf xml) and identifier type(i.e. URL, uuid, ISBN, etc)
  # === Book#add_identifier(string, id, type=nil) (delegated to Metadata#add_identifier)
  # set identifier. it it not set as unique-identifier of EPUB.
  # === Book#add_title(content, id = nil, title_type = nil) (delegated to Metadata#add_title)
  # add title metadata. default title_type is defined in TITLE_TYPES.
  # === Book#set_title(content, id = nil, title_type = nil) (delegated to Metadata#set_title)
  # clear all titles and then add title.
  # === Book#title (delegated to Metadata)
  # returns 'main' title Meta object. 'main' title is determined by this order:
  # 1. title-type is  'main'
  # 2. display-seq is smallest
  # 3. appears first in opf file
  # === Book#title_list (delegated to Metadata)
  # returns titles list by display-seq or defined order.
  # the title without display-seq is appear after titles with display-seq.
  # === Book#add_creator(content, id = nil, role = 'aut') (delegated to Metadata#add_creator)
  # add creator.
  # === Book#creator
  # returns 'main' creator Meta object. 'main' creatoris determined by this order:
  # 1. display-seq is smallest
  # 2. appears first in opf file
  # === Book#creator_list (delegated to Metadata)
  # returns creators list by display-seq or defined order.
  # the creators without display-seq is appear after creators with display-seq.
  # === Book#add_contributor(content, id = nil, role = 'aut') (delegated to Metadata#add_contributor)
  # add contributor.
  # === Book#contributor(content, id = nil, role = 'aut') (delegated to Metadata#contributor)
  # returns 'main' contributor. 'main' contributor determined by this order:
  # 1. display-seq is smallest
  # 2. appears first in opf file
  # === Book#contributors_list (delegated to Metadata)
  # returns contributors list by display-seq or defined order.
  # the contributors without display-seq is appear after contributors with display-seq.
  # === Book#set_lastmodified(date=nil) (delegated to Metadata#set_lastmodified)
  # set last modified date.if date is nil, it sets current time.
  # === Book#lastmodified (delegated to Metadata#lastmodified)
  # returns Meta object contains last modified time.
  # === setting and reading other metadata: publisher, language, coverage, date, description, format, relation, rights, source, subject, type (delegated to Metadata)
  # they all have methods like: publisher(which returns 'main' publisher), add_publisher(content, id) (which add publisher), set_publisher or publisher= (clears and set publisher), and publisher_list(returns publisher Meta object in display-seq order). 
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

    # Parses existing EPUB2/EPUB3 files from an IO object, and creates new Book object.
    #   book = self.parse(File.new('some.epub'))

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
              if files[MIMETYPE] != MIMETYPE_CONTENTS
                warn "#{MIMETYPE} is not valid: should be #{MIMETYPE_CONTENTS} but was #{files[MIMETYPE]}"
              end
              files.delete(MIMETYPE)
            when CONTAINER then
              package_path = rootfile_from_container(files[CONTAINER])
              files.delete(CONTAINER)
            when ROOTFILE_PATTERN then
              package = Package.parse_opf(files[entry.name], entry.name)
              files.delete(entry.name)
            end
          end
        end

        if package.nil?
          raise 'this container do not cotains publication information file'
        end
        
        if package_path != package.path
          warn 'inconsistend EPUB file: container says opf is #{package_path}, but actually #{package.path}'
        end
        
        files.each {
          |k, content|
          item = package.manifest.item_by_href(k.sub(/^#{package.contents_prefix}/,''))
          if !item.nil?
            files.delete(k)
            item.add_raw_content(content)
          end
        }
        book = Book.new(package.path)
        book.instance_eval { @package = package; @stray_files = files }
        book
      }
    end

    # creates new empty Book object.
    # usually you do not need to specify any arguments.

    def initialize(path='OEBPS/package.opf', attributes = {})
      if File.extname(path) != '.opf'
        warn 'GEPUB::Book#new interface changed. You must supply path to package.opf as first argument. If you want to set title, please use GEPUB::Book#title='
      end
      @package = Package.new(path, attributes)
      @toc = []
      yield book if block_given?
    end

    # add navigation text (which will appear on navigation document or table of contents) to an item.
    # DEPRECATED: please use Item#toc_text or Item#toc_text_with_id, or Builder#heading

    def add_nav(item, text, id = nil)
      warn 'add_nav is deprecated: please use Item#toc_text'
      @toc.push({ :item => item, :text => text, :id => id})      
    end

    # add an item(i.e. html, images, audios, etc)  to Book.
    # the added item will be referenced by the first argument in the EPUB container.
    def add_item(href, io_or_filename = nil, id = nil, attributes = {})
      item = @package.add_item(href,io_or_filename,id,attributes)
      toc = @toc
      metaclass = (class << item;self;end)
      metaclass.send(:define_method, :toc_text,
                                    Proc.new { |text|
                                      toc.push(:item => item, :text => text, :id => nil)
                                      item
                     })
      metaclass.send(:define_method, :toc_text_with_id,
                                    Proc.new { |text, id|
                                      toc.push(:item => item, :text => text, :id => id)
                                      item
                     })
      
      yield item if block_given?
      item
    end

    # same as add_item, but the item will be added to spine of the EPUB.

    def add_ordered_item(href, io_or_filename = nil, id = nil, attributes = {})
      item = @package.add_ordered_item(href,io_or_filename,id,attributes)
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

    # should call ordered() with block.
    # within the block, all item added by add_item will be added to spine also.
    def ordered(&block)
      @package.ordered(&block)
    end

    # clenup and maintain consistency of metadata and items included in the Book
    # object. 
    def cleanup
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
        
        @package.spine.remove_with_idlist @package.manifest.item_list.map {
          |href, item|
          item.fallback
        }.reject(&:nil?)

      end
    end

    # write EPUB to stream specified by the argument.
    def write_to_epub_container(epub) 
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
    end

    # generates and returns StringIO contains EPUB.
    def generate_epub_stream
      cleanup
      Zip::ZipOutputStream::write_buffer {
        |epub|
        write_to_epub_container(epub)
      }
    end

    # writes EPUB to file. if file exists, it will be overwritten.
    def generate_epub(path_to_epub)
      cleanup
      File.delete(path_to_epub) if File.exist?(path_to_epub)
      Zip::ZipOutputStream::open(path_to_epub) {
        |epub|
        write_to_epub_container(epub)
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
                  id = x[:id].nil? ? "" : "##{x[:id]}"
                  doc.li {
                    doc.a({'href' => x[:item].href + id} ,x[:text])
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
