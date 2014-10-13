# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
describe GEPUB::Builder do
  context 'metadata generating' do
    it 'should generate language' do
      builder = GEPUB::Builder.new {
        language 'ja'
      }
      expect(builder.instance_eval { @book.language }.to_s).to eq('ja')
    end

    it 'should generate uid' do
      builder = GEPUB::Builder.new {
        unique_identifier 'http://example.jp/as_url', 'BookID', 'url'
      }
      expect(builder.instance_eval { @book.identifier }.to_s).to eq('http://example.jp/as_url')
      expect(builder.instance_eval { @book.identifier_list[0]['id']}).to eq('BookID')
      expect(builder.instance_eval { @book.identifier_list[0].identifier_type}.to_s).to eq('url')
    end
    
    it 'should generate title' do
      builder = GEPUB::Builder.new {
        title 'The Book Title'
      }
      expect(builder.instance_eval { @book.title }.to_s).to eq('The Book Title')
      expect(builder.instance_eval { @book.title.title_type }.to_s).to eq('main')
    end

    it 'should generate title with type ' do
      builder = GEPUB::Builder.new {
        subtitle 'the sub-title'
      }
      expect(builder.instance_eval { @book.title }.to_s).to eq('the sub-title')
      expect(builder.instance_eval { @book.title.title_type }.to_s).to eq('subtitle')
    end

    it 'should generate collection title ' do
      builder = GEPUB::Builder.new {
        collection 'the collection', 3
      }
      expect(builder.instance_eval { @book.title }.to_s).to eq('the collection')
      expect(builder.instance_eval { @book.title.title_type }.to_s).to eq('collection')
      expect(builder.instance_eval { @book.title.group_position }.to_s).to eq('3')
    end

    it 'should refine title: alternates ' do
      builder = GEPUB::Builder.new {
        collection 'the collection', 3
        alt 'ja' => 'シリーズ'
      }
      expect(builder.instance_eval { @book.title }.to_s).to eq('the collection')
      expect(builder.instance_eval { @book.title.title_type }.to_s).to eq('collection')
      expect(builder.instance_eval { @book.title.list_alternates['ja'] }.to_s).to eq('シリーズ')
    end

    it 'should refine title: file_as ' do
      builder = GEPUB::Builder.new {
        title 'メインタイトル'
        file_as 'main title'
      }
      expect(builder.instance_eval { @book.title }.to_s).to eq('メインタイトル')
      expect(builder.instance_eval { @book.title.title_type }.to_s).to eq('main')
      expect(builder.instance_eval { @book.title.file_as }.to_s).to eq('main title')
    end

    it 'should refine title: alt and file_as ' do
      builder = GEPUB::Builder.new {
        title 'メインタイトル'
        file_as 'main title'
        alt 'en' => 'The Main Title'
      }
      expect(builder.instance_eval { @book.title }.to_s).to eq('メインタイトル')
      expect(builder.instance_eval { @book.title.title_type }.to_s).to eq('main')
      expect(builder.instance_eval { @book.title.file_as }.to_s).to eq('main title')
      expect(builder.instance_eval { @book.title.list_alternates['en'] }.to_s).to eq('The Main Title')
    end

    it 'should generate creator ' do
      builder = GEPUB::Builder.new {
        creator 'The Main Author'
      }
      expect(builder.instance_eval { @book.creator }.to_s).to eq('The Main Author')
    end

    it 'should generate creator with role' do
      builder = GEPUB::Builder.new {
        creator 'The Illustrator', 'ill'
      }
      expect(builder.instance_eval { @book.creator }.to_s).to eq('The Illustrator')
      expect(builder.instance_eval { @book.creator.role}.to_s).to eq('ill')
    end

    it 'should generate contributor ' do
      builder = GEPUB::Builder.new {
        contributor 'contributor', 'edt'
      }
      expect(builder.instance_eval { @book.contributor }.to_s).to eq('contributor')
      expect(builder.instance_eval { @book.contributor.role}.to_s).to eq('edt')
    end

    it 'should generate multiple creators ' do
      builder = GEPUB::Builder.new {
        creators 'First Author', 'Second Author', ['Third Person', 'edt']
      }
      expect(builder.instance_eval { @book.creator_list }.size).to eq(3)
      expect(builder.instance_eval { @book.creator_list[0] }.to_s).to eq('First Author')
      expect(builder.instance_eval { @book.creator_list[1] }.to_s).to eq('Second Author')
      expect(builder.instance_eval { @book.creator_list[2] }.to_s).to eq('Third Person')
      expect(builder.instance_eval { @book.creator_list[2].role }.to_s).to eq('edt')
    end

    it 'should generate multiple creators, and then add file_as at once ' do
      builder = GEPUB::Builder.new {
        creators 'First Author', 'Second Author', ['Third Person', 'edt']
        file_as '1st', '2nd', '3rd'
      }
      expect(builder.instance_eval { @book.creator_list }.size).to eq(3)
      expect(builder.instance_eval { @book.creator_list[0] }.to_s).to eq('First Author')
      expect(builder.instance_eval { @book.creator_list[0].file_as }.to_s).to eq('1st')
      expect(builder.instance_eval { @book.creator_list[1] }.to_s).to eq('Second Author')
      expect(builder.instance_eval { @book.creator_list[1].file_as }.to_s).to eq('2nd')
      expect(builder.instance_eval { @book.creator_list[2] }.to_s).to eq('Third Person')
      expect(builder.instance_eval { @book.creator_list[2].file_as }.to_s).to eq('3rd')
      expect(builder.instance_eval { @book.creator_list[2].role }.to_s).to eq('edt')
    end


    it 'should generate multiple creators, and multiple alternates ' do
      builder = GEPUB::Builder.new {
        creators 'First Author', 'Second Author', ['Third Person', 'edt']
        alts(
             'ja' => ['最初','二番目', '三番目'],
             'en' => ['first','second','third']
             )
      }
      expect(builder.instance_eval { @book.creator_list }.size).to eq(3)
      expect(builder.instance_eval { @book.creator_list[0] }.to_s).to eq('First Author')
      expect(builder.instance_eval { @book.creator_list[0].list_alternates['ja'] }.to_s).to eq('最初')
      expect(builder.instance_eval { @book.creator_list[0].list_alternates['en'] }.to_s).to eq('first')
      expect(builder.instance_eval { @book.creator_list[1] }.to_s).to eq('Second Author')
      expect(builder.instance_eval { @book.creator_list[1].list_alternates['ja'] }.to_s).to eq('二番目')
      expect(builder.instance_eval { @book.creator_list[1].list_alternates['en'] }.to_s).to eq('second')
      expect(builder.instance_eval { @book.creator_list[2] }.to_s).to eq('Third Person')
      expect(builder.instance_eval { @book.creator_list[2].list_alternates['ja'] }.to_s).to eq('三番目')
      expect(builder.instance_eval { @book.creator_list[2].list_alternates['en'] }.to_s).to eq('third')
      expect(builder.instance_eval { @book.creator_list[2].role }.to_s).to eq('edt')
    end
  end
  context 'resources' do
    it 'should add a file to book' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          file('text/memo.txt')
        }
      }
      expect(builder.instance_eval{ @book.item_by_href('text/memo.txt') }).not_to be_nil
      expect(builder.instance_eval{ @book.item_by_href('text/memo.txt').content.chomp }).to eq('just a plain text.')
    end

    it 'should add files to book' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          files('text/memo.txt','text/cover.xhtml')
        }
      }
      expect(builder.instance_eval{ @book.item_by_href('text/memo.txt') }).not_to be_nil
      expect(builder.instance_eval{ @book.item_by_href('text/memo.txt').content.chomp }).to eq('just a plain text.')
      expect(builder.instance_eval{ @book.item_by_href('text/cover.xhtml') }).not_to be_nil
    end

    it 'should add files to book with glob' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          glob 'text/*.{txt,xhtml}'
        }
      }
      expect(builder.instance_eval{ @book.item_by_href('text/memo.txt') }).not_to be_nil
      expect(builder.instance_eval{ @book.item_by_href('text/memo.txt').content.chomp }).to eq('just a plain text.')
      expect(builder.instance_eval{ @book.item_by_href('text/cover.xhtml') }).not_to be_nil
    end

    it 'should add files to book with import with prefix' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          import 'text/localresource.conf'
        }
      }
      expect(builder.instance_eval{ @book.item_by_href('memo.txt') }).not_to be_nil
      expect(builder.instance_eval{ @book.item_by_href('memo.txt').content.chomp }).to eq('just a plain text.')
      expect(builder.instance_eval{ @book.item_by_href('cover.xhtml') }).not_to be_nil
    end

    it 'should add files to book with import with prefix' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          import 'text/localresource.conf', :dir_prefix => 'text'
        }
      }
      expect(builder.instance_eval{ @book.item_by_href('text/memo.txt') }).not_to be_nil
      expect(builder.instance_eval{ @book.item_by_href('text/memo.txt').content.chomp }).to eq('just a plain text.')
      expect(builder.instance_eval{ @book.item_by_href('text/cover.xhtml') }).not_to be_nil
    end

    it 'should add a file with id' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          file('text/memo.txt')
          id 'the_id_of_memo.txt'
        }
      }
      expect(builder.instance_eval{ @book.item_by_href('text/memo.txt') }).not_to be_nil
      expect(builder.instance_eval{ @book.item_by_href('text/memo.txt').id }).to eq('the_id_of_memo.txt')
    end

    it 'should add files to book from IO object' do
      io = File.new(File.join(File.dirname(__FILE__),'fixtures', 'builder', 'text', 'memo.txt'))
      builder = GEPUB::Builder.new {
        resources()  {
          file('text/memo.txt' => io)
        }
      }
      expect(builder.instance_eval{ @book.item_by_href('text/memo.txt') }).not_to be_nil
      expect(builder.instance_eval{ @book.item_by_href('text/memo.txt').content.chomp }).to eq('just a plain text.')
    end

    it 'should add image file as cover' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          cover_image 'img/cover.jpg'
        }
      }
      expect(builder.instance_eval{ @book.item_by_href('img/cover.jpg') }).not_to be_nil
      expect(builder.instance_eval{ @book.item_by_href('img/cover.jpg').properties.member? 'cover-image' }).to eq(true)
    end

    it 'should add file as nav' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          nav 'text/nav.xhtml'
        }
      }
      expect(builder.instance_eval{ @book.item_by_href('text/nav.xhtml') }).not_to be_nil
      expect(builder.instance_eval{ @book.item_by_href('text/nav.xhtml').properties.member? 'nav' }).to eq(true)
    end

    it 'should specify mediatype' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          file('resources/noise.m4')
          media_type('audio/mp4')
        }
      }
      expect(builder.instance_eval{ @book.item_by_href('resources/noise.m4') }).not_to be_nil        
      expect(builder.instance_eval{ @book.item_by_href('resources/noise.m4').media_type }).to eq('audio/mp4')
    end

    it 'should specify mediatype to files' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          files('resources/noise.m4', 'resources/noise_2.m4a')
          media_type('audio/mp4')
        }
      }
      expect(builder.instance_eval{ @book.item_by_href('resources/noise.m4') }).not_to be_nil        
      expect(builder.instance_eval{ @book.item_by_href('resources/noise.m4').media_type }).to eq('audio/mp4')

      expect(builder.instance_eval{ @book.item_by_href('resources/noise_2.m4a') }).not_to be_nil        
      expect(builder.instance_eval{ @book.item_by_href('resources/noise_2.m4a').media_type }).to eq('audio/mp4')
    end

    it 'should specify mediatype to files using with_media_type' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          with_media_type('audio/mp4') {
            file('resources/noise.m4')
            file('resources/noise_2.m4a')
          }
          file('text/cover.xhtml')
        }
      }
      expect(builder.instance_eval{ @book.item_by_href('resources/noise.m4') }).not_to be_nil        
      expect(builder.instance_eval{ @book.item_by_href('resources/noise.m4').media_type }).to eq('audio/mp4')

      expect(builder.instance_eval{ @book.item_by_href('resources/noise_2.m4a') }).not_to be_nil        
      expect(builder.instance_eval{ @book.item_by_href('resources/noise_2.m4a').media_type }).to eq('audio/mp4')

      expect(builder.instance_eval{ @book.item_by_href('text/cover.xhtml') }).not_to be_nil        
      expect(builder.instance_eval{ @book.item_by_href('text/cover.xhtml').media_type }).to eq('application/xhtml+xml')
    end

    it 'should specify bindings handler' do
      builder = GEPUB::Builder.new {
        resources {
          file 'scripts/handler.xhtml' => nil
          handles 'application/x-some-foregin-type'
        }
      }
      builder.instance_eval{
        @book.get_handler_of('application/x-some-foregin-type').id ==  @book.item_by_href('scripts/handler.xhtml').id
      }
    end
    
    it 'should add files to book in spine' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          ordered {
            file('text/cover.xhtml')
            file('text/memo.txt')
          }
        }
      }
      expect(builder.instance_eval{ @book.item_by_href('text/cover.xhtml') }).not_to be_nil
      expect(builder.instance_eval{ @book.spine_items[0].href }).to eq('text/cover.xhtml')
      expect(builder.instance_eval{ @book.item_by_href('text/memo.txt') }).not_to be_nil
      expect(builder.instance_eval{ @book.spine_items[1].href }).to eq('text/memo.txt')
    end

    it 'should add files and heading' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          ordered {
            file('text/cover.xhtml')
            heading 'cover page'
            file('text/memo.txt')
            heading 'memo text'
          }
        }
      }
      expect(builder.instance_eval{ @book.item_by_href('text/cover.xhtml') }).not_to be_nil
      expect(builder.instance_eval{ @book.spine_items[0].href }).to eq('text/cover.xhtml')
      expect(builder.instance_eval{ @book.item_by_href('text/memo.txt') }).not_to be_nil
      expect(builder.instance_eval{ @book.spine_items[1].href }).to eq('text/memo.txt')
      expect(builder.instance_eval{ @book.instance_eval { @toc[0][:item].href }}).to eq('text/cover.xhtml')
      expect(builder.instance_eval{ @book.instance_eval { @toc[0][:text] }}).to eq('cover page')
      expect(builder.instance_eval{ @book.instance_eval { @toc[1][:item].href }}).to eq('text/memo.txt')
      expect(builder.instance_eval{ @book.instance_eval { @toc[1][:text] }}).to eq('memo text')
    end

    it 'should add files and page-spread-property' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          ordered {
            file('text/cover.xhtml')
            page_spread_left
            file('text/memo.txt')
            page_spread_right
          }
        }
      }
      expect(builder.instance_eval{ @book.item_by_href('text/cover.xhtml') }).not_to be_nil
      expect(builder.instance_eval{ @book.spine.itemref_list[0].properties[0] }).to eq('page-spread-left')
      expect(builder.instance_eval{ @book.item_by_href('text/memo.txt') }).not_to be_nil
      expect(builder.instance_eval{ @book.spine.itemref_list[1].properties[0] }).to eq('page-spread-right')
    end

    it 'should add files and rendition property' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          ordered {
            file('text/cover.xhtml')
            file('text/memo.txt')
            rendition_layout 'pre-paginated'
            rendition_orientation 'landscape'
            rendition_spread 'both'
          }
        }
      }
      expect(builder.instance_eval{ @book.item_by_href('text/memo.txt') }).not_to be_nil
      expect(builder.instance_eval{ @book.spine.itemref_list[1].properties[0] }).to eq('rendition:layout-pre-paginated')
      expect(builder.instance_eval{ @book.spine.itemref_list[1].properties[1] }).to eq('rendition:orientation-landscape')
      expect(builder.instance_eval{ @book.spine.itemref_list[1].properties[2] }).to eq('rendition:spread-both')
      xml = builder.instance_eval{
        Nokogiri::XML::Document.parse @book.opf_xml
      }
      expect(xml.root['prefix']).to eq 'rendition: http://www.idpf.org/vocab/rendition/#'
    end

    it 'whould handle ibooks version' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        ibooks_version '1.1.1'
        resources(:workdir => workdir)  {
          ordered {
            file('text/cover.xhtml')
            file('text/memo.txt')
          }
        }
      }
      xml =  builder.instance_eval{
        Nokogiri::XML::Document.parse @book.opf_xml
      }
      expect(xml.root['prefix']).to eq 'ibooks: http://vocabulary.itunes.apple.com/rdf/ibooks/vocabulary-extensions-1.0/'
      expect(xml.at_xpath("//xmlns:meta[@property='ibooks:version']").content).to eq '1.1.1'
    end

    it 'handle ibooks scroll-axis' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        ibooks_scroll_axis :vertical
        resources(:workdir => workdir)  {
          ordered {
            file('text/cover.xhtml')
            file('text/memo.txt')
          }
        }
      }
      xml =  builder.instance_eval{
        Nokogiri::XML::Document.parse @book.opf_xml
      }
      expect(xml.root['prefix']).to eq 'ibooks: http://vocabulary.itunes.apple.com/rdf/ibooks/vocabulary-extensions-1.0/'
      expect(xml.at_xpath("//xmlns:meta[@property='ibooks:scroll-axis']").content).to eq 'vertical'
    end

    it 'should handle fallback chain' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          fallback_group {
            file 'chap3_docbook.xml' => nil
            media_type('application/docbook+xml')
            file 'chap3.xml' => nil
            media_type("application/z3986-auth+xml")
            file 'chap3.xhtml' => nil
          }
        }
      }
      book = builder.instance_eval {
        @book
      }
      fallbackid = book.item_by_href('chap3_docbook.xml').fallback
      expect(book.items[fallbackid].href).to eq 'chap3.xml'
      fallbackid = book.items[fallbackid].fallback
      expect(book.items[fallbackid].href).to eq 'chap3.xhtml'        
    end

    it 'should handle fallback chain with fallback_chain_files' do
      # in this test, do not supply 
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          fallback_chain_files({'chap3_docbook.xml' => nil}, {'chap3.xml' => nil}, {'chap3.xhtml' => nil})
        }
      }
      book = builder.instance_eval { @book }
      fallbackid = book.item_by_href('chap3_docbook.xml').fallback
      expect(book.items[fallbackid].href).to eq 'chap3.xml'
      fallbackid = book.items[fallbackid].fallback
      expect(book.items[fallbackid].href).to eq 'chap3.xhtml'
    end

    it 'should handle fallback chain with fallback_chain_files in with_media_type' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          with_media_type('application/docbook+xml', 'application/z3986-auth+xml', 'application/xhtml+xml') {
            fallback_chain_files({'chap3_docbook.xml' => nil}, {'chap3.xml' => nil}, {'chap3.xhtml' => nil})
          }
        }
      }
      book =  builder.instance_eval { @book }
      expect(book.item_by_href('chap3_docbook.xml').media_type).to eq 'application/docbook+xml'
      fallbackid = book.item_by_href('chap3_docbook.xml').fallback
      expect(book.items[fallbackid].href).to eq 'chap3.xml'
      expect(book.items[fallbackid].media_type).to eq 'application/z3986-auth+xml'

      fallbackid = book.items[fallbackid].fallback
      expect(book.items[fallbackid].href).to eq 'chap3.xhtml'        
      expect(book.items[fallbackid].media_type).to eq 'application/xhtml+xml'
    end

    it 'should handle fallback chain in spine' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        unique_identifier 'uid'

        resources(:workdir => workdir)  {
          ordered {
            fallback_group {
              file 'chap3_docbook.xml' => nil
              media_type('application/docbook+xml')
              file 'chap3.xml' => nil
              media_type("application/z3986-auth+xml")
              file 'chap3.xhtml' => nil
            }
          }
        }
      }
      book = builder.instance_eval { @book }
      book.cleanup
      fallbackid = book.item_by_href('chap3_docbook.xml').fallback
      expect(book.items[fallbackid].href).to eq 'chap3.xml'
      fallbackid = book.items[fallbackid].fallback
      expect(book.items[fallbackid].href).to eq 'chap3.xhtml'

      expect(book.spine_items.size).to eq 1
      book.spine_items[0].href == 'chap3_docbook.xhtml'
    end

    it 'should create remote-resources' do
      builder = GEPUB::Builder.new {
        unique_identifier 'uid'
        resources {
          file 'with_remote.xhtml' => StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops"><head></head><body><div><p><video src="http://foo.bar">no video</video></p></div></body></html>')
        }
      }
      prop = builder.instance_eval {
        @book.item_by_href('with_remote.xhtml').properties[0]
      }
      expect(prop).to eq 'remote-resources'
    end

    it 'should handle remote resource URL' do
      GEPUB::Builder.new {
        unique_identifier 'uid'
        resources {
          file 'http://foo.bar'
        }
      }
      # this should not raise 'No such file or directory'
    end

    it 'should handle mathml' do
      builder = GEPUB::Builder.new {
        unique_identifier 'uid'
        resources {
          file 'mathml.xhtml' => StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops"><head></head><body><div><p><math xmlns="http://www.w3.org/1998/Math/MathML"></math></p></div></body></html>')
        }
      }
      prop = builder.instance_eval {
        @book.item_by_href('mathml.xhtml').properties[0]
      }
      expect(prop).to eq 'mathml'
    end

    it 'should handle svg' do
      builder = GEPUB::Builder.new {
        unique_identifier 'uid'
        resources {
          file 'svg.xhtml' => StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops"><head></head><body><div><p><svg xmlns="http://www.w3.org/2000/svg"></svg></p></div></body></html>')
        }
      }
      prop = builder.instance_eval {
        @book.item_by_href('svg.xhtml').properties[0]
      }
      expect(prop).to eq 'svg'
    end

    it 'should handle epub:switch' do
      builder = GEPUB::Builder.new {
        unique_identifier 'uid'
        resources {
          file 'switch.xhtml' => StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops"><head></head><body><div><p>
<epub:switch>
   <epub:case required-namespace="http://www.xml-cml.org/schema">
      <cml xmlns="http://www.xml-cml.org/schema">
         <molecule id="sulfuric-acid">
            <formula id="f1" concise="H 2 S 1 O 4"/>
         </molecule>
      </cml>
   </epub:case>
   <epub:default>
      <p>H<sub>2</sub>SO<sub>4</sub></p>
   </epub:default>
</epub:switch></p></div></body></html>')
        }
      }
      prop = builder.instance_eval {
        @book.item_by_href('switch.xhtml').properties[0]
      }
      expect(prop).to eq 'switch'
    end

    it 'should handle scripted property' do
      builder = GEPUB::Builder.new {
        unique_identifier 'uid'
        resources {
          file 'scripted.xhtml' => StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops"><head><script>alert("scripted");</script></head><body><div><p>text comes here</p></div></body></html>')
        }
      }
      expect(builder.instance_eval {
        @book.item_by_href('scripted.xhtml').properties[0]
      }).to eq 'scripted'
    end

    it 'should handle optional file' do
      builder = GEPUB::Builder.new {
        optional_file 'META-INF/test.xml' => StringIO.new('<test></test>')
      }
      expect(builder.instance_eval {
        @book.optional_files.size
      }).to eq 1
      
      expect(builder.instance_eval {      
        @book.optional_files['META-INF/test.xml']
      }).not_to be_nil
    end
  end
end
