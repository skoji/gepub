# -*- coding: utf-8 -*-
require 'rubygems'
require 'nokogiri'
require 'zip'
require 'fileutils'

# = GEPUB 
# Author:: KOJIMA Satoshi
# namespace for gepub library.
# The core class is GEPUB::Book. It holds metadata and contents of EPUB file. metadata and contents can be accessed
# through GEPUB::Meta and GEPUB::Item.
# For generating EPUB file,  use GEPUB::Builder.
# GEPUB::Item holds information and data  of resources like xhtml text, css, scripts, images, videos, etc.
# GEPUB::Meta holds metadata(title, creator, publisher, etc.) with its information (alternate script, display sequence, etc.)

module GEPUB
  # Book is the class to hold data in EPUB files.
  # 
  # It can generate and parse EPUB2/EPUB3 files.
  #
  # If you want to generate a new EPUB file, consider using GEPUB::Builder instead
  # of using Book directly.
  # Builder is a wrapper class of Book specialized for generating EPUB.
  # 
  # Book delegates many methods to objects in other class, so you can't find
  # them in Book#methods or in ri/rdoc documentation. Their descriptions are below.
  #
  # == \Package Attributes
  # === Book#version (delegated to Package#version)
  # returns OPF version.
  # === Book#version=, Book#set_version (delegated to Package#version=)
  # set OPF version
  # === Book#unique_identifier (delegated to Package#unique_identifier)
  # return unique_identifier ID value. identifier itself can be get by Book#identifier
  # == \Metadata
  # \Metadata items(e.g. title, creator, publisher, etc) are GEPUB::Meta objects.
  # === Book#identifier (delegated to Package#identifier)
  # return GEPUB::Meta object of unique identifier.
  # === Book#identifier=(identifier)   (delegated to Package#identifier=)
  # set identifier (i.e. url, uuid, ISBN) as unique-identifier of EPUB.
  # === Book#set_main_id(identifier, id = nil, type = nil)   (delegated to Package#set_main_id)
  # same as identifier=, but can specify id (in the opf xml) and identifier type(i.e. URL, uuid, ISBN, etc)
  # === Book#add_identifier(string, id, type=nil) (delegated to Metadata#add_identifier)
  # Set an identifier metadata. It it not unique-identifier in opf. Many EPUB files do not set identifier other than unique-identifier.
  # === Book#add_title(content, id = nil, title_type = nil) (delegated to Metadata#add_title)
  # add title metadata. title_type candidates is defined in TITLE_TYPES.
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
  # returns 'main' creator Meta object. 'main' creator is determined as following:
  # 1. display-seq is smallest
  # 2. appears first in opf file
  # === Book#creator_list (delegated to Metadata)
  # returns creators list by display-seq or defined order.
  # the creators without display-seq is appear after creators with display-seq.
  # === Book#add_contributor(content, id = nil, role = 'aut') (delegated to Metadata#add_contributor)
  # add contributor.
  # === Book#contributor(content, id = nil, role = 'aut') (delegated to Metadata#contributor)
  # returns 'main' contributor. 'main' contributor determined as following:
  # 1. display-seq is smallest
  # 2. appears first in opf file
  # === Book#contributors_list (delegated to Metadata)
  # returns contributors list by display-seq or defined order.
  # the contributors without display-seq is appear after contributors with display-seq.
  # === Book#lastmodified(date) (delegated to Metadata#lastmodified)
  # set last modified date.
  # === Book#modified_now (delegated to Metadata#modified_now)
  # set last modified date to current time.
  # === Book#lastmodified (delegated to Metadata#lastmodified)
  # returns Meta object contains last modified time.
  # === setting and reading other metadata: publisher, language, coverage, date, description, format, relation, rights, source, subject, type (delegated to Metadata)
  # they all have methods like: publisher(which returns 'main' publisher), add_publisher(content, id) (which add publisher), set_publisher or publisher= (clears and set publisher), and publisher_list(returns publisher Meta object in display-seq order). 
  # === Book#page_progression_direction= (delegated to Spine#page_progression_direction=)
  # set page-proression-direction attribute to spine.

  class Book
    MIMETYPE='mimetype'
    MIMETYPE_CONTENTS='application/epub+zip'
    CONTAINER='META-INF/container.xml'
    ROOTFILE_PATTERN=/^.+\.opf$/
    CONTAINER_NS='urn:oasis:names:tc:opendocument:xmlns:container'

    def self.rootfile_from_container(rootfile)
      doc = Nokogiri::XML::Document.parse(rootfile)
      ns = doc.root.namespaces
      defaultns = ns.select{ |name, value| value == CONTAINER_NS }.to_a[0][0]
      doc.css("#{defaultns}|rootfiles > #{defaultns}|rootfile")[0]['full-path']
    end

    # Parses existing EPUB2/EPUB3 files from an IO object, and creates new Book object.
    #   book = self.parse(File.new('some.epub'))

    def self.parse(io)
      files = {}
      package = nil
      package_path = nil
      book = nil
      Zip::InputStream::open(io) {
        |zis|
        package, package_path = parse_container(zis, files)
        check_consistency_of_package(package, package_path)
        parse_files_into_package(files, package)
        book = Book.new(package.path)
        book.instance_eval { @package = package; @optional_files = files }
      }
      book
    end

    # creates new empty Book object.
    # usually you do not need to specify any arguments.
    def initialize(path='OEBPS/package.opf', attributes = {}, &block)
      if File.extname(path) != '.opf'
        warn 'GEPUB::Book#new interface changed. You must supply path to package.opf as first argument. If you want to set title, please use GEPUB::Book#title='
      end
      @package = Package.new(path, attributes)
      @toc = []
      if block
        block.arity < 1 ? instance_eval(&block) : block[self]        
      end
    end


    # Get optional(not required in EPUB specification) files in the container.
    def optional_files
      @optional_files || {}
    end

    # Add an optional file to the container
    def add_optional_file(path, io_or_filename)
      io = io_or_filename
      if io_or_filename.class == String
        io = File.new(io_or_filename)
      end
      io.binmode
      (@optional_files ||= {})[path] = io.read
    end
    
    def set_singleton_methods_to_item(item)
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
      bindings = @package.bindings
      metaclass.send(:define_method, :is_handler_of,
                     Proc.new { |media_type|
                       bindings.add(item.id, media_type)
                       item
                     })
                               
    end
    
    # add an item(i.e. html, images, audios, etc)  to Book.
    # the added item will be referenced by the first argument in the EPUB container.
    def add_item(href, io_or_filename = nil, id = nil, attributes = {})
      item = @package.add_item(href,nil,id,attributes)
      set_singleton_methods_to_item(item)
      item.add_content io_or_filename unless io_or_filename.nil?
      item
    end

    # same as add_item, but the item will be added to spine of the EPUB.
    def add_ordered_item(href, io_or_filename = nil, id = nil, attributes = {})
      item = @package.add_ordered_item(href,io_or_filename,id,attributes)
      set_singleton_methods_to_item(item)
      yield item if block_given?
      item
    end


    # get handler item which defined in bindings for media type, 
    def get_handler_of(media_type)
      items[@package.bindings.handler_by_media_type[media_type]]
    end

    def method_missing(name,*args, &block)
      @package.send(name, *args, &block)
    end

    # should call ordered() with block.
    # within the block, all item added by add_item will be added to spine also.
    def ordered(&block)
      @package.ordered(&block)
    end

    # clenup and maintain consistency of metadata and items included in the Book
    # object. 
    def cleanup
      cleanup_for_epub2
      cleanup_for_epub3
    end

    # write EPUB to stream specified by the argument.
    def write_to_epub_container(epub)
      epub.put_next_entry('mimetype', '', '', Zip::Entry::STORED)
      epub << "application/epub+zip"

      entries = {}
      optional_files.each {
        |k, content|
        entries[k] = content
      }

      entries['META-INF/container.xml'] = container_xml
      entries[@package.path] = opf_xml
      @package.manifest.item_list.each {
        |k, item|
        if item.content != nil
          entries[@package.contents_prefix + item.href] = item.content
        end
      }

      entries.sort_by { |k,v| k }.each {
        |k,v|
        epub.put_next_entry(k)
        epub << v.force_encoding('us-ascii')
      }
    end

    # generates and returns StringIO contains EPUB.
    def generate_epub_stream
      cleanup
      Zip::OutputStream::write_buffer(StringIO.new) do
        |epub|
        write_to_epub_container(epub)
      end
    end

    # writes EPUB to file. if file exists, it will be overwritten.
    def generate_epub(path_to_epub)
      cleanup
      File.delete(path_to_epub) if File.exist?(path_to_epub)
      Zip::OutputStream::open(path_to_epub) {
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


    # add tocdata like this : [ {link: chapter1.xhtml, text: 'Capter 1', level: 1} ] .
    # if item corresponding to the link does not exists, error will be thrown.
    def add_tocdata(toc_yaml)
      newtoc = []
      toc_yaml.each do |toc_entry|
        href, id = toc_entry[:link].split('#')
        item = @package.manifest.item_by_href(href)
        throw "#{href} does not exist." if item.nil?
        newtoc.push({item: item, id: id, text: toc_entry[:text], level: toc_entry[:level] })
      end
      @toc = @toc + newtoc
    end
      
    def generate_nav_doc(title = 'Table of Contents')
      add_item('nav.xhtml', StringIO.new(nav_doc(title)), 'nav').add_property('nav')
    end
    
    def nav_doc(title = 'Table of Contents')
      # handle cascaded toc
      start_level = @toc && @toc[0][:level] || 1
      stacked_toc = {level: start_level, tocs: [] }
      @toc.inject(stacked_toc) do |current_stack, toc_entry|
        toc_entry_level = toc_entry[:level] || 1
        if current_stack[:level] < toc_entry_level
          new_stack = { level: toc_entry_level, tocs: [], parent: current_stack}
          current_stack[:tocs].last[:child_stack] = new_stack
          current_stack = new_stack
        else
          while current_stack[:level] > toc_entry_level and
               !current_stack[:parent].nil?
            current_stack = current_stack[:parent]
          end
        end
        current_stack[:tocs].push toc_entry
        current_stack
      end
      # write toc 
      def write_toc xml_doc, tocs
        xml_doc.ol {
          tocs.each {
            |x|
            id = x[:id].nil? ? "" : "##{x[:id]}"
            toc_text = x[:text]
            toc_text = x[:item].href if toc_text.nil? or toc_text == ''
            xml_doc.li {
              xml_doc.a({'href' => x[:item].href + id} ,toc_text)
              if x[:child_stack] && x[:child_stack][:tocs].size > 0
                write_toc(xml_doc, x[:child_stack][:tocs])
              end
            }
          }
        }
      end
      # build nav
      builder = Nokogiri::XML::Builder.new {
        |doc|
        doc.html('xmlns' => "http://www.w3.org/1999/xhtml",'xmlns:epub' => "http://www.idpf.org/2007/ops") {
          doc.head { doc.text ' ' }
          doc.body {
            doc.nav('epub:type' => 'toc', 'id' => 'toc') {
              doc.h1 "#{title}"
              write_toc(doc, stacked_toc[:tocs])
            }
          }
        }
      }
      builder.to_xml(:encoding => 'utf-8')
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
              xml.navPoint('id' => "#{x[:item].itemid}_#{x[:id]}", 'playOrder' => "#{count}") {
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
      builder.to_xml(:encoding => 'utf-8')
    end
    
    private
    def self.parse_container(zis, files) 
      package_path = nil
      package = nil
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
      return package, package_path
    end

    def self.check_consistency_of_package(package, package_path)
      if package.nil?
        raise 'this container do not cotains publication information file'
      end

      if package_path != package.path
        warn 'inconsistend EPUB file: container says opf is #{package_path}, but actually #{package.path}'
      end
    end
    def self.parse_files_into_package(files, package)
      files.each {
        |k, content|
        item = package.manifest.item_by_href(k.sub(/^#{package.contents_prefix}/,''))
        if !item.nil?
          files.delete(k)
          item.add_raw_content(content)
        end
      }
    end
    def  cleanup_for_epub2
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
    end
    def cleanup_for_epub3
      if version.to_f >=3.0
        @package.metadata.modified_now
        
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
  end
end
