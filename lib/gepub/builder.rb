# -*- coding: utf-8 -*-
module GEPUB
  #
  # Builder is a wrapper class of Book. It provides DSL to create new EPUB file.
  #
  # = Synopsys
  #      # -*- coding: utf-8 -*-
  #      # GEPUB::Builder example.
  #      require 'ruby gem'
  #      require 'gepub'
  #
  #      builder = GEPUB::Builder.new {
  #        # In the root block, you can define metadata.
  #        # You can define title, creator(s), contributor(s), publisher(s), date, unique_identifier, identifier, language.
  #        # Title can be specified with title, subtitle, collection, short_title, expanded_title, edition. 
  #        # You can also define description, format, relation, right, source, subject, type.
  #        # You can 'refine' last-defined metadata by refiner/attributes methods
  #        # Refiner methods contains : file_as, alt 
  #        
  #
  #        language 'ja'
  #
  #        title 'タイトル'
  #        alt 'en' => 'main title'
  #        file_as 'main title'
  #
  #        subtitle 'サブタイトル'  
  #        alt 'en' => 'subtitle'
  #
  #        # collection title and position in the collection:
  #        collection 'gepub sample book series', 2
  #
  #        #specifying creator
  #        creator 'author1','aut'
  #        alt 'ja' =>'日本語名' ,'en' =>'english name for author1'
  #        id 'the_first_author'
  #
  #        #specifying multiple creator
  #        creators 'author1', 'author2', ['editor1', 'edt']
  #
  #        contributor 'contributor'
  #        contributors 'contributor1', 'contributor2'
  #        # easy way to write alt {'ja' =>'日本語 for contributor1'}, {'ja' => '日本語 for contributor2'}
  #        alts 'ja' => ['日本語 for contributor1','日本語 for contributor2'] 
  #
  #        publisher '出版社'
  #        alt 'en' => 'ThePublisher'
  #        
  #        date '2012-02-21T00:00:00Z'
  #
  #        unique_identifier 'the_unique_id_in_uuid', 'uuid'
  #        identifier 'http://other_id','url'
  #        identifier 'http://another_id','url'
  #
  #        # in resources block, you can define resources by its relative path and datasource.
  #        # item creator methods are: files, file.
  #        resources(:workdir => '~/epub_source') {
  #          # Reads from file. in EPUB container, they are placed at the same path.
  #          file 'img/image0.jpg'
  #          files('img/image.jpg','img/image2.jpg')
  #          glob 'img/*.jpg' # means files(Dir.glob('img/*.jpg'))
  #
  #          # Reads from file. will be placed at path indicated by key.
  #          files('img/image.jpg' => 'imgage.jpg')
  #
  #          # Read from IO object.
  #          files('img/image.png' => supplied_io, 'img/image2.png' => supplied_io2)
  #
  #          # this will be end in error:
  #          # files(io1, io2)
  #
  #          # specify remote resource.
  #          # only referenced from the EPUB package.
  #          file 'http://example.com/video/remote_video.qt'
  #          media_type('video/quicktime')
  #
  #          # specify media type. 
  #          file 'resources/pv.mp4'
  #          media_type('video/mp4')
  #
  #          files('audio/voice1.mp4','audio/music1.mp4')
  #          media_type('audio/mp4')  # applied to all items in the line above.
  #
  #          # media_type to some file
  #          with_media_type('video/mp4') {
  #            file 'resources/v1.mp4'
  #            file 'resources/v2.mp4'
  #            file 'resources/v3.mp4'
  #          }
  #
  #          # with_media_type and media_type 
  #          with_media_type('video/mp4') {
  #            file 'resources/v1.mp4'
  #            file 'resources/v2.mp4'
  #            file 'resources/a4.mp4'
  #            media_type 'audio/mp4' # override with_media_type
  #          }
  #
  #          # Read from IO object: loop
  #          # supplied_IOs = { 'path' => io, 'path' => io... }
  #          supplied_IOs.each {
  #            |name, io|
  #            file name => io
  #          }
  #
  #          file 'css/default.css'
  #
  #          # indicate property.
  #          # this is cover image.
  #          cover_image 'img/cover.jpg'
  #
  #          # this is navigation document.
  #          nav 'text/toc.xhtml'
  #
  #          # ordered item. will be added to spine.
  #          ordered {
  #            # specify texts on table of contents for auto-generated toc.
  #            # (if you supply navigation document with method 'nav',  'heading' has no effect.)
  #            file('text/chap1.xhtml')
  #            heading 'Chapter 1'
  #            file 'text/chap2.xhtml'
  #            
  #            # fallback chain: style 1
  #            fallback_group {
  #              file 'chap3_docbook.xhtml'
  #              mimetype('application/docbook+xml')
  #              file 'chap3.xml'
  #              mimetype "application/z3986-auth+xml"
  #              file 'chap3.xhtml'
  #            }
  #
  #            # fallback chain: style 2
  #            fallback_chain_files 'chap4_docbook.xhtml', 'chap4.xml', 'chap4.xhtml'
  #            mimetype('application/docbook+xml','application/z3986-auth+xml' 'application/xhtml+xml')
  #
  #            # fallback chain: style 3 + with_mimetype
  #            with_mimetype('application/docbook+xml','application/z3986-auth+xml' 'application/xhtml+xml') {
  #              fallback_chain_files 'chap5_docbook.xhtml', 'chap5.xml', 'chap5.xhtml' 
  #              fallback_chain_files 'chap6_docbook.xhtml', 'chap6.xml', 'chap6.xhtml' 
  #              fallback_chain_files 'chap7_docbook.xhtml', 'chap7.xml', 'chap7.xhtml' 
  #            }
  #
  #          }
  #        }
  #      }
  #
  #      builder.generate_epub('sample.epub')


  class Builder
    include BuilderMixin
    class MetaItem
      def initialize(item)
        @item = item
      end

      def apply_one_to_multi
        false
      end

      def alt(alternates = {})
        @item.add_alternates(alternates)
      end

      def file_as(name)
        @item.file_as(name)
      end

      def seq(num)
        @item.display_seq(num)
      end

      def group_position(num)
        @item.group_position(num)
      end

      def id(val)
        @item['id'] = val
      end
    end

    def initialize(attributes = {},  &block)
      @last_defined_item = nil
      @book = Book.new
      instance_eval(&block)
      # TODO check @book's consistency
      true
    end

    # define base methods.
    GEPUB::Metadata::CONTENT_NODE_LIST.each {
      |name|
      if !["title", "creator", "contributor"].include?(name)
        define_method(name) { |val| @last_defined_item = MetaItem.new(@book.send("add_#{name}".to_sym, val, nil)) }
      end
    }

    GEPUB::TITLE_TYPE::TYPES.each {
      |type|
      case type
      when 'main'
        methodname = 'title'
      when 'short'
        methodname = 'short_title'
      when 'expanded'
        methodname = 'expanded_title'
      else
        methodname = type
      end
      if methodname != "collection"
        define_method(methodname) { |val| @last_defined_item = MetaItem.new(@book.add_title(val, nil, type)) }
      end
    }

    def collection(val, count = 1)
      @last_defined_item =
        MetaItem.new(@book.add_title(val, nil, GEPUB::TITLE_TYPE::COLLECTION).group_position(count.to_s))
    end

    def creator(val, role = 'aut')
      MetaItem.new(@book.add_creator(val, nil, role))
    end

    def creators(*vals)
      @last_defined_item = vals.map {
        |v|
        name = v
        role = 'aut'
        name,role = v[0], v[1] if Array === name
        MetaItem.new(@book.add_creator(name, nil, role))
      }
    end

    def contributors(*vals)
      @last_defined_item = vals.map {
        |v|
        name = v
        role = nil
        name,role = v[0], v[1] if Array === name
        MetaItem.new(@book.add_contributor(name, nil, role))
      }
    end

    def publishers(*vals)
      @last_defined_item = vals.map {
        |v|
        MetaItem.new(@book.add_publisher(v, nil))
      }
    end

    def unique_identifier(val, id = 'BookID', scheme = 'nil')
      @last_defined_item = MetaItem.new(@book.primary_identifier(val, id, scheme))
    end
    
    def alts(alt_vals = {})
      raise "can't specify alts on single item" if ! Array === @last_defined_item
      @last_defined_item.each_with_index {
        |item, index| 
        item.alt Hash[*(alt_vals.map{|k,v| [k,v[index]]}.flatten)]
      }
    end
    
    def contributor(val, role = nil)
      MetaItem.new(@book.add_contributor(val, nil, role))
    end

    # set page progression direction.
    def page_progression_direction(val)
      raise assert unless ['rtl', 'ltr', 'default'].member? val
      @book.page_progression_direction = val
    end
    # specify version for ibooks
    def ibooks_version(val)
      @book.ibooks_version=val
    end
    # specify scroll axis for ibooks
    def ibooks_scroll_axis(val)
      @book.ibooks_scroll_axis = val
    end
    
    # set optional file.
    # val should be String or Hash.
    # if val is String, file is read from the File specified by string and stored in EPUB to the path specified by string.
    # if val is Hash, file is read from the value and stored in EPUB to the path specified by the key.
    def optional_file(val)
      path = val
      io = val if String === val
      if Hash === val
        raise 'argument to optional_file should be length 1' if val.size != 1
        path = val.first[0]
        io = val.first[1]
      end
      @book.add_optional_file(path, io)
    end
    
    def generate_epub(path_to_epub)
      @book.generate_epub(path_to_epub)
    end

    def resources(attributes = {}, &block)
      ResourceBuilder.new(@book, attributes, &block)
    end
    def book
      @book
    end
    def generate_epub_stream
      @book.generate_epub_stream
    end
  end
end
