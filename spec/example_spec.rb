# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'

describe 'GEPUB usage' do
  context 'On using Builder' do
  end
  
  context 'On generating EPUB' do
    it 'should generate simple EPUB3 with Builder and buffer' do
      workdir = File.join(File.dirname(__FILE__),  'fixtures', 'testdata')
      builder = GEPUB::Builder.new {
        unique_identifier 'http:/example.jp/bookid_in_url', 'BookID', 'URL'
        language 'ja'
        title 'GEPUBサンプル文書'
        file_as 'GEPUB Sample Book'
        alt 'en' => 'GEPUB Sample Book (Japanese)',
        'el' => 'GEPUB δείγμα (Ιαπωνικά)',
        'th' => 'GEPUB ตัวอย่าง (ญี่ปุ่น)'

        subtitle 'これはあくまでサンプルです'
        alt 'en' => 'This book is just a sample'
        creator '小嶋智'
        contributors 'Denshobu', 'Asagaya Densho', 'Shonan Densho Teidan', 'eMagazine Torutaru'
        resources(:workdir => workdir) {
          cover_image 'img/image1.jpg' => 'image1.jpg'
          ordered {
            file 'text/chap1.xhtml' => StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c1</title></head><body><p>the first page</p></body></html>')
            heading 'Chapter 1'
            file 'text/chap1-1.xhtml' => StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c2</title></head><body><p>the second page</p></body></html>')
            file 'text/chap2.xhtml' => StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c3</title></head><body><p>the third page</p></body></html>')
            heading 'Chapter 2'
          }
        }
      }
      epubname = File.join(File.dirname(__FILE__), 'example_test_with_builder_buffer.epub')
      File.open(epubname, 'wb') { |io| io.write builder.generate_epub_stream.string }
      epubcheck(epubname)
    end

    it 'should generate simple EPUB3 with Builder' do
      workdir = File.join(File.dirname(__FILE__),  'fixtures', 'testdata')
      builder = GEPUB::Builder.new {
        unique_identifier 'http:/example.jp/bookid_in_url', 'BookID', 'URL'
        language 'ja'
        title 'GEPUBサンプル文書'
        file_as 'GEPUB Sample Book'
        alt 'en' => 'GEPUB Sample Book (Japanese)',
        'el' => 'GEPUB δείγμα (Ιαπωνικά)',
        'th' => 'GEPUB ตัวอย่าง (ญี่ปุ่น)'

        subtitle 'これはあくまでサンプルです'
        alt 'en' => 'This book is just a sample'
        creator '小嶋智'
        contributors 'Denshobu', 'Asagaya Densho', 'Shonan Densho Teidan', 'eMagazine Torutaru'
        resources(:workdir => workdir) {
          cover_image 'img/image1.jpg' => 'image1.jpg'
          ordered {
            file 'text/chap1.xhtml' => StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c1</title></head><body><p>the first page</p></body></html>')
            heading 'Chapter 1'
            file 'text/chap1-1.xhtml' => StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c2</title></head><body><p>the second page</p></body></html>')
            file 'text/chap2.xhtml' => StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c3</title></head><body><p>the third page</p></body></html>')
            heading 'Chapter 2'
          }
        }
      }
      epubname = File.join(File.dirname(__FILE__), 'example_test_with_builder.epub')
      builder.generate_epub(epubname)
      epubcheck(epubname)
    end

    it 'should generate simple EPUB3 with rather complicated matadata' do
      book = GEPUB::Book.new
      book.primary_identifier('http:/example.jp/bookid_in_url', 'BookID', 'URL')
      book.language = 'ja'

      # you can add metadata and its property using block
      book.add_title('GEPUBサンプル文書', nil, GEPUB::TITLE_TYPE::MAIN) {
        |title|
        title.lang = 'ja'
        title.file_as = 'GEPUB Sample Book'
        title.display_seq = 1
        title.add_alternates(
                             'en' => 'GEPUB Sample Book (Japanese)',
                             'el' => 'GEPUB δείγμα (Ιαπωνικά)',
                             'th' => 'GEPUB ตัวอย่าง (ญี่ปุ่น)')
      }
      # you can do the same thing using method chain
      book.add_title('これはあくまでサンプルです',nil, GEPUB::TITLE_TYPE::SUBTITLE).display_seq(2).add_alternates('en' => 'this book is just a sample.')
      book.add_creator('小嶋智') {
        |creator|
        creator.display_seq = 1
        creator.add_alternates('en' => 'KOJIMA Satoshi')
      }
      book.add_contributor('電書部').display_seq(1).add_alternates('en' => 'Denshobu')
      book.add_contributor('アサガヤデンショ').display_seq(2).add_alternates('en' => 'Asagaya Densho')
      book.add_contributor('湘南電書鼎談').display_seq(3).add_alternates('en' => 'Shonan Densho Teidan')
      book.add_contributor('電子雑誌トルタル').display_seq(4).add_alternates('en' => 'eMagazine Torutaru')

      imgfile = File.join(File.dirname(__FILE__),  'fixtures', 'testdata', 'image1.jpg')
      book.add_item('img/image1.jpg',imgfile).cover_image
      
      # within ordered block, add_item will be added to spine.
      book.ordered {
        book.add_item('text/chap1.xhtml').add_content(StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c1</title></head><body><p>the first page</p></body></html>')).toc_text('Chapter 1')
        book.add_item('text/chap1-1.xhtml').add_content(StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c2</title></head><body><p>the second page</p></body></html>')) # do not appear on table of contents
        book.add_item('text/chap2.xhtml').add_content(StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c3</title></head><body><p>the third page</p></body></html>')).toc_text('Chapter 2')
      }
      epubname = File.join(File.dirname(__FILE__), 'example_test.epub')
      book.generate_epub(epubname)
      epubcheck(epubname)
    end
  end
end
