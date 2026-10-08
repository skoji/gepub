# -*- coding: utf-8 -*-
require 'rubygems'
require 'nokogiri'
require 'zip_kit'
require 'zlib'
require 'fileutils'

# = GEPUB
# Author:: KOJIMA Satoshi
# namespace for gepub library.
# The core class is GEPUB::Book. It holds metadata and contents of EPUB file. metadata and contents can be accessed
# through GEPUB::Meta and GEPUB::Item.
# GEPUB::Item holds information and data  of resources like xhtml text, css, scripts, images, videos, etc.
# GEPUB::Meta holds metadata(title, creator, publisher, etc.) with its information (alternate script, display sequence, etc.)

module GEPUB
  # Book is the class to hold data in EPUB files.
  #
  # It can generate and parse EPUB2/EPUB3 files.
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
  # === Book#add_title(content, id: nil, title_type: nil) (delegated to Metadata#add_title)
  # add title metadata. title_type candidates is defined in TITLE_TYPES.
  # === Book#title(content, id = nil, title_type = nil) (delegated to Metadata#title)
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
  # set last modified date. date is a Time, DateTime or string that can be parsed by DateTime#parse.
  # === Book#modified_now (delegated to Metadata#modified_now)
  # set last modified date to current time.
  # === Book#lastmodified (delegated to Metadata#lastmodified)
  # returns Meta object contains last modified time.
  # === setting and reading other metadata: publisher, language, coverage, date, description, format, relation, rights, source, subject, type (delegated to Metadata)
  # they all have methods like: publisher(which returns 'main' publisher), add_publisher(content, id) (which add publisher), publisher= (clears and set publisher), and publisher_list(returns publisher Meta object in display-seq order).
  # === Book#page_progression_direction= (delegated to Spine#page_progression_direction=)
  # set page-proression-direction attribute to spine.

  # raised when a Book that streams its EPUB out gets asked to do something it no longer can,
  # such as changing content which has already been written
  StreamingError = Class.new(StandardError)

  class Book
    include InspectMixin

    MIMETYPE='mimetype'
    MIMETYPE_CONTENTS='application/epub+zip'
    CONTAINER='META-INF/container.xml'
    ROOTFILE_PATTERN=/^.+\.opf$/
    CONTAINER_NS='urn:oasis:names:tc:opendocument:xmlns:container'

    def self.rootfile_from_container(rootfile)
      doc = Nokogiri::XML::Document.parse(rootfile)
      ns = doc.root.namespaces
      defaultns = ns.select{ |_name, value| value == CONTAINER_NS }.to_a[0][0]
      doc.css("#{defaultns}|rootfiles > #{defaultns}|rootfile")[0]['full-path']
    end

    # Parses existing EPUB2/EPUB3 files from an IO object or a file path and creates new Book object.
    #   book = self.parse(File.new('some.epub'))

    def self.parse(path_or_io)
      files = {}
      package = nil
      package_path = nil
      book = nil
      with_zip_io(path_or_io) do
        |zip_io|
        package, package_path = parse_container(zip_io, files)
        check_consistency_of_package(package, package_path)
        parse_files_into_package(files, package)
        book = Book.new(package.path)
        book.instance_eval { @package = package; @optional_files = files }
      end
      book
    end

    # builds the Book in the block and writes the EPUB into `io` while the block runs: the content
    # of every item gets written out as soon as it is added, and is not kept in memory. Everything
    # which needs the whole book - package.opf, the navigation documents - gets written at the end.
    # `io` can be anything responding to `<<` or `write`, or a ZipKit::Streamer - such as the one
    # yielded by `zip_kit_stream` in Rails. Returns `io`.
    #
    #   GEPUB::Book.write_epub(File.open('book.epub', 'wb')) do |book|
    #     book.title = 'Streamed'
    #     book.ordered { chapters.each { |c| book.add_item(c.href, content: c.io).toc_text(c.title) } }
    #   end
    #
    # The content of an item can only be added once. Metadata, such as the toc text or properties
    # of items, can be changed until the block returns.
    def self.write_epub(io, path = 'OEBPS/package.opf', attributes = {}, &block)
      with_epub_streamer(io) { |epub| new(path, attributes).stream_to_epub_container(epub, &block) }
      io
    end

    # same as `write_epub`, but returns a Rack response body. The block only runs once the
    # body gets iterated over - that is, while the response is being sent. Errors from the block
    # will be raised from `each`, after the response status and headers have been sent.
    def self.rack_body(path = 'OEBPS/package.opf', attributes = {}, &block)
      ZipKit::OutputEnumerator.new(ocf: true) { |epub| new(path, attributes).stream_to_epub_container(epub, &block) }
    end

    # creates new empty Book object.
    # usually you do not need to specify any arguments.
    def initialize(path='OEBPS/package.opf', attributes = {}, &block)
      if File.extname(path) != '.opf'
        warn 'GEPUB::Book#new interface changed. You must supply path to package.opf as first argument. If you want to set title, please use GEPUB::Book#title='
      end
      @package = Package.new(path, attributes)
      @toc = []
      @landmarks = []
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
      if @streaming_epub
        @streaming_epub.write_file(path, modification_time: zip_modification_time) { |sink| IO.copy_stream(io, sink) }
      else
        (@optional_files ||= {})[path] = io.read
      end
    end

    def set_singleton_methods_to_item(item)
      toc = @toc
      metaclass = (class << item;self;end)
      metaclass.send(:define_method, :toc, Proc.new {
        toc
      })
      landmarks = @landmarks
      metaclass.send(:define_method, :landmarks, Proc.new {
        landmarks
      })
      bindings = @package.bindings
      metaclass.send(:define_method, :bindings, Proc.new {
        bindings
      })

    end


    # get handler item which defined in bindings for media type,
    def get_handler_of(media_type)
      items[@package.bindings.handler_by_media_type[media_type]]
    end

    ruby2_keywords def method_missing(name, *args, &block)
      @package.send(name, *args, &block)
    end

    # should call ordered() with block.
    # within the block, all item added by add_item will be added to spine also.
    def ordered(&block)
      @package.ordered(&block)
    end

    # cleanup and maintain consistency of metadata and items included in the Book
    # object.
    def cleanup
      cleanup_for_epub2
      cleanup_for_epub3
    end

    # write EPUB to ZipKit::Streamer specified by the argument.
    def write_to_epub_container(epub)
      raise_if_streamed
      mod_time = zip_modification_time

      epub.write_mimetype_file(MIMETYPE_CONTENTS, modification_time: mod_time)

      entries = {}
      optional_files.each {
        |k, content|
        entries[k] = content
      }

      entries[CONTAINER] = container_xml
      entries[@package.path] = opf_xml
      @package.manifest.item_list.each {
        |_k, item|
        if item.content != nil
          entries[@package.contents_prefix + item.href] = item.content
        end
      }

      entries.sort_by { |k,_v| k }.each {
        |k,v|
        write_zip_entry(epub, k, v, mod_time)
      }
    end

    # writes the EPUB into the ZipKit::Streamer while the block builds the Book, see Book.write_epub
    def stream_to_epub_container(epub, &block)
      raise_if_streamed
      @streamed = true
      @streaming_epub = epub
      # Fixed upfront, since cleanup sets the lastmodified halfway through the entries
      @streaming_mod_time = zip_modification_time
      epub.write_mimetype_file(MIMETYPE_CONTENTS, modification_time: zip_modification_time)
      write_zip_entry(epub, CONTAINER, container_xml, zip_modification_time)
      block.arity < 1 ? instance_eval(&block) : block[self] if block

      # This adds the nav and ncx, which get streamed out like any other item
      cleanup
      # Content which bypassed add_content, for instance via Item#content=
      @package.manifest.item_list.each_value do |item|
        stream_item_content(item, item.content) unless item.content.nil?
      end
      write_zip_entry(epub, @package.path, opf_xml, zip_modification_time)
    ensure
      @streaming_epub = nil
      @streaming_mod_time = nil
    end

    # writes EPUB to the argument, which can be anything responding to `<<` or `write` -
    # a File, a socket, a Rack streaming body and so on - or a ZipKit::Streamer. The output is
    # written as it gets generated, without assembling the whole EPUB in memory first. Returns the argument.
    #   book.write_epub($stdout)
    def write_epub(io)
      raise_if_streamed
      cleanup
      self.class.send(:with_epub_streamer, io) { |epub| write_to_epub_container(epub) }
      io
    end

    # generates and returns StringIO contains EPUB.
    def generate_epub_stream
      write_epub(StringIO.new(String.new))
    end

    # writes EPUB to file. if file exists, it will be overwritten.
    def generate_epub(path_to_epub)
      File.open(path_to_epub, 'wb') { |f| write_epub(f) }
    end

    # returns an object which yields the EPUB in chunks from `each`, usable as a Rack response body.
    # The EPUB only gets generated once the body is iterated over, but `cleanup` runs right away.
    # Errors which occur while writing - such as a file name which is not allowed in an EPUB -
    # are raised from `each`, which will be after the response status and headers have been sent.
    def to_rack_body
      raise_if_streamed
      cleanup
      ZipKit::OutputEnumerator.new(ocf: true) { |epub| write_to_epub_container(epub) }
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


    # add tocdata like this : [ {link: chapter1.xhtml, text: 'Chapter 1', level: 1} ] .
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
      add_item('nav.xhtml', id: 'nav', content: StringIO.new(nav_doc(title))).add_property('nav')
    end

    def nav_doc(title = 'Table of Contents')
      # handle cascaded toc
      start_level = @toc && !@toc.empty? && @toc[0][:level] || 1
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
        return if tocs.empty?
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
      def write_landmarks xml_doc, landmarks
        xml_doc.ol {
          landmarks.each {
            |landmark|
            id = landmark[:id].nil? ? "" : "##{x[:id]}"
            landmark_title = landmark[:title]
            xml_doc.li {
              xml_doc.a({'href' => landmark[:item].href + id, 'epub:type' => landmark[:type]}, landmark_title)
            }
          }
        }
      end
      # build nav
      builder = Nokogiri::XML::Builder.new {
        |doc|
        unless version.to_f < 3.0
          doc.doc.create_internal_subset('html', nil, nil )
        end
        doc.html('xmlns' => "http://www.w3.org/1999/xhtml",'xmlns:epub' => "http://www.idpf.org/2007/ops") {
          doc.head {
            doc.title title
          }
          doc.body {
            if !stacked_toc.empty?
              doc.nav('epub:type' => 'toc', 'id' => 'toc') {
                doc.h1 "#{title}"
                write_toc(doc, stacked_toc[:tocs])
              }
            end
            if !@landmarks.empty?
              doc.nav('epub:type' => 'landmarks', 'id' => 'landmarks') {
                write_landmarks(doc, @landmarks)
              }
            end
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
    def raise_if_streamed
      raise StreamingError, 'This Book has been streamed out, and does not hold its content anymore' if @streamed
    end

    def zip_modification_time
      return @streaming_mod_time if @streaming_mod_time
      return Time.now if (last_mod = lastmodified).nil?
      tm = last_mod.content
      Time.local(tm.year, tm.month, tm.day, tm.hour, tm.min, tm.sec)
    end

    # Precompressed, so that the sizes go into the local header and no data descriptor is needed
    def write_zip_entry(epub, name, content, mod_time)
      data = content.b
      deflated = Zlib::Deflate.new(Zlib::DEFAULT_COMPRESSION, -Zlib::MAX_WBITS).deflate(data, Zlib::FINISH)
      epub.add_deflated_entry(filename: name, modification_time: mod_time, compressed_size: deflated.bytesize,
                              uncompressed_size: data.bytesize, crc32: Zlib.crc32(data))
      epub << deflated
    end

    def stream_item_content(item, string_or_io)
      name = @package.contents_prefix + item.href
      if string_or_io.is_a?(String)
        write_zip_entry(@streaming_epub, name, string_or_io, zip_modification_time)
        item.content = nil
      else
        @streaming_epub.write_file(name, modification_time: zip_modification_time) { |sink| IO.copy_stream(string_or_io, sink) }
      end
    end

    # A Streamer responds to `<<` too, and would get a whole ZIP written into it as one entry body.
    # A Streamer we did not create must have been opened with `ocf: true` by the caller
    def self.with_epub_streamer(io, &block)
      return yield(io) if io.is_a?(ZipKit::Streamer)
      ZipKit::Streamer.open(io, ocf: true, &block)
    end
    private_class_method :with_epub_streamer

    def self.with_zip_io(path_or_io)
      return yield(path_or_io) if path_or_io.respond_to?(:seek)
      File.open(path_or_io, 'rb') { |f| yield(f) }
    end
    private_class_method :with_zip_io

    def self.parse_container(zip_io, files)
      package_path = nil
      package = nil
      ZipKit::FileReader.read_zip_structure(io: zip_io).each do |entry|
        unless entry.filename.end_with?('/')
          files[entry.filename] = read_entry(entry, zip_io)
          case entry.filename
          when MIMETYPE then
            if files[MIMETYPE] != MIMETYPE_CONTENTS
              warn "#{MIMETYPE} is not valid: should be #{MIMETYPE_CONTENTS} but was #{files[MIMETYPE]}"
            end
            files.delete(MIMETYPE)
          when CONTAINER then
            package_path = rootfile_from_container(files[CONTAINER])
            files.delete(CONTAINER)
          when ROOTFILE_PATTERN then
            package = Package.parse_opf(files[entry.filename], entry.filename)
            files.delete(entry.filename)
          end
        end
      end
      return package, package_path
    end
    private_class_method :parse_container

    def self.read_entry(entry, zip_io)
      reader = entry.extractor_from(zip_io)
      data = +''
      data << reader.extract(64 * 1024) until reader.eof?
      data
    end
    private_class_method :read_entry

    def self.check_consistency_of_package(package, package_path)
      if package.nil?
        raise 'this container do not contains publication information file'
      end

      if package_path != package.path
        warn "inconsistent EPUB file: container says opf is #{package_path}, but actually #{package.path}"
      end
    end
    private_class_method :check_consistency_of_package

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
    private_class_method :parse_files_into_package

    def  cleanup_for_epub2
      if version.to_f < 3.0 || @package.epub_backward_compat
        if @package.manifest.item_list.select {
          |_x,item|
          item.media_type == 'application/x-dtbncx+xml'
        }.size == 0
          if (@toc.size == 0 && !@package.spine.itemref_list.empty?)
            @toc << { :item => @package.manifest.item_list[@package.spine.itemref_list[0].idref] }
          end
          add_item('toc.ncx', id: 'ncx', content: StringIO.new(ncx_xml))
        end
      end
    end
    def cleanup_for_epub3
      if version.to_f >=3.0
        @package.metadata.modified_now unless @package.metadata.lastmodified_updated?

        if @package.manifest.item_list.select {
          |_href, item|
          (item.properties||[]).member? 'nav'
          }.size == 0
          generate_nav_doc
        end

        @package.spine.remove_with_idlist @package.manifest.item_list.map {
          |_href, item|
          item.fallback
        }.reject(&:nil?)
      end
    end

    private

    def add_item_internal(href, content: nil, item_attributes: , attributes: {}, ordered: )
      id = item_attributes.delete(:id)
      # While streaming, the content gets added once the sink is in place, so that it goes straight out
      package_content = @streaming_epub ? nil : content
      item =
        if ordered
          @package.add_ordered_item(href,attributes: attributes, id:id, content: package_content)
        else
          @package.add_item(href, attributes: attributes, id: id, content: package_content)
        end
      set_singleton_methods_to_item(item)
      if @streaming_epub
        item.content_sink = method(:stream_item_content)
        item.add_content(content) unless content.nil?
      end
      item_attributes.each do |attr, val|
        next if val.nil?
        method_name = if attr == :toc_text
                        ""
                      elsif attr == :property
                        "add_"
                      else
                        "set_"
                      end + attr.to_s
        item.send(method_name, val)
      end
      item
    end


  end
end
