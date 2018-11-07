require 'rubygems'
require 'gepub'

book = GEPUB::Book.new
book.primary_identifier('http://example.jp/bookid_in_url', 'BookID', 'URL')
book.language = 'ja'

book.add_title 'GEPUBサンプル文書', 
               title_type: GEPUB::TITLE_TYPE::MAIN,
               lang: 'ja',
               file_as: 'GEPUB Sample Book',
               display_seq: 1,
               alternates: {
                       'en' => 'GEPUB Sample Book (Japanese)',
                       'el' => 'GEPUB δείγμα (Ιαπωνικά)',
                       'th' => 'GEPUB ตัวอย่าง (ญี่ปุ่น)' }
               
# you can do the same thing using method chain
book.add_title('これはあくまでサンプルです', title_type: GEPUB::TITLE_TYPE::SUBTITLE).display_seq(1).add_alternates('en' => 'this book is just a sample.')

# use arguments
book.add_creator '小嶋智', 
                 display_seq:1, 
                 alternates: { 'en' => 'KOJIMA Satoshi' } 
book.add_contributor '電書部',
                     display_seq: 1,
                     alternates: {'en' => 'Denshobu'}
book.add_contributor 'アサガヤデンショ',
                     display_seq: 2, 
                     alternates: {'en' => 'Asagaya Densho'}
# you can also use method chain
book.add_contributor('湘南電書鼎談').display_seq(3).add_alternates('en' => 'Shonan Densho Teidan')
book.add_contributor('電子雑誌トルタル').display_seq(4).add_alternates('en' => 'eMagazine Torutaru')

imgfile = File.join(File.dirname(__FILE__),  'image1.jpg')
File.open(imgfile) do
  |io|
  book.add_item('img/image1.jpg',content: io).cover_image
end

# within ordered block, add_item will be added to spine.
book.ordered {
  book.add_item('text/cover.xhtml',
                content: StringIO.new(<<-COVER)).landmark(type: 'cover', title: 'cover page')
                <html xmlns="http://www.w3.org/1999/xhtml">
                <head>
                  <title>cover page</title>
                </head>
                <body>
                <h1>The Book</h1>
                <img src="../img/image1.jpg" />
                </body></html>
  COVER
  book.add_item('text/chap1.xhtml').add_content(StringIO.new(<<-CHAP_ONE)).toc_text('Chapter 1').landmark(type: 'bodymatter', title: '本文')
  <html xmlns="http://www.w3.org/1999/xhtml">
  <head><title>c1</title></head>
  <body><p>the first page</p></body></html>
  CHAP_ONE
  book.add_item('text/chap1-1.xhtml').add_content(StringIO.new(<<-SEC_ONE_ONE)) # do not appear on table of contents
  <html xmlns="http://www.w3.org/1999/xhtml">
  <head><title>c2</title></head>
  <body><p>the second page</p></body></html>
  SEC_ONE_ONE
  book.add_item('text/chap2.xhtml').add_content(StringIO.new(<<-CHAP_TWO)).toc_text('Chapter 2')
  <html xmlns="http://www.w3.org/1999/xhtml">
  <head><title>c3</title></head>
  <body><p>the third page</p></body></html>
  CHAP_TWO
  # to add nav file:
  # book.add_item('path/to/nav').add_content(nav_html_content).add_property('nav')
}
epubname = File.join(File.dirname(__FILE__), 'example_test.epub')

# if you do not specify your own nav document with add_item, 
# simple navigation text will be generated in generate_epub.
# auto-generated nav file will not appear on spine.
book.generate_epub(epubname)

