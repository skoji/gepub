# gepub  

[![GitHub Actions Status](https://github.com/skoji/gepub/workflows/Test/badge.svg)](https://github.com/skoji/gepub/actions?query=workflow%3ATest)
[![Gem Version](https://badge.fury.io/rb/gepub.svg?icon=si%3Arubygems)](https://badge.fury.io/rb/gepub)

* https://rubydoc.info/github/skoji/gepub

## DESCRIPTION:

a generic EPUB parser/generator library.

## FEATURES/PROBLEMS:

* GEPUB::Book provides functionality to create EPUB files and parse EPUB files
* Handle every metadata in EPUB2/EPUB3.

* See [issues](https://github.com/skoji/gepub/issues/) for known problems.

If you are using GEPUB::Builder and do not like its behavior (e.g., GEPUB::Builder evaluates the block as inside the Builder instance),  consider using GEPUB::Book directly.

## SYNOPSIS:

### Example

```ruby
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

# if you do not specify a nav document with add_item, 
# generate_epub will generate simple navigation text.
# auto-generated nav file will not appear on the spine.
book.generate_epub(epubname)
```
 * [examples in this repository](https://github.com/skoji/gepub/tree/main/examples/) 

### Streaming output

`generate_epub` and `generate_epub_stream` are built on `write_epub`, which writes the EPUB as it gets
generated, into anything that responds to `<<` or `write` - a socket, a pipe, `$stdout`:

```ruby
book.write_epub($stdout)
```

### Building the book while streaming

The book still holds all of its content in memory until it gets written. To avoid that, build the book
inside a block given to `GEPUB::Book.write_epub`. The content of every item is then written out as soon as
it gets added, and does not stay in memory:

```ruby
GEPUB::Book.write_epub(File.open('audiobook.epub', 'wb')) do |book|
  book.identifier = 'urn:uuid:5c8a6b7e-0a5f-4b6e-9c1d-2f1e3a4b5c6d'
  book.title = 'A very long audiobook'
  book.language = 'en'

  book.ordered do
    chapters.each do |chapter|
      item = book.add_item("text/#{chapter.slug}.xhtml", content: StringIO.new(chapter.xhtml))
      item.toc_text(chapter.title)
    end
  end

  tracks.each do |track|
    File.open(track.path, 'rb') do |io|
      book.add_item("audio/#{track.slug}.mp3", content: io)
    end
  end
end
```

Media and other non-XHTML content is copied through from its IO without being read whole. XHTML is read
item by item, because gepub inspects it to set item properties such as `svg` or `mathml`. Everything which
needs the whole book - `package.opf` and the navigation documents - is written when the block returns.

Since the content is gone once written, it can only be added once per item, and the book can not be
generated again afterwards. Metadata - the title, toc texts, landmarks, item properties - can be changed
until the block returns. `GEPUB::Builder.write_epub` takes the same block as `GEPUB::Builder.new`.

### Sending an EPUB from Rails

gepub writes EPUBs with [zip_kit](https://github.com/julik/zip_kit), which adds `zip_kit_stream` to your
controllers. Give the block it yields to `GEPUB::Book.write_epub`, and the book gets built while it is
being downloaded - even the database queries for its content happen during the download:

```ruby
class PublicationsController < ApplicationController
  def download
    publication = Publication.find(params[:id])

    zip_kit_stream(filename: "#{publication.slug}.epub", type: 'application/epub+zip', ocf: true) do |zip|
      GEPUB::Book.write_epub(zip) do |book|
        book.identifier = "urn:uuid:#{publication.uuid}"
        book.title = publication.title
        book.language = publication.language

        book.ordered do
          publication.chapters.order(:position).each do |chapter|
            item = book.add_item("text/chapter-#{chapter.position}.xhtml", content: StringIO.new(chapter.xhtml))
            item.toc_text(chapter.title)
          end
        end
      end
    end
  end
end
```

Pass `ocf: true` to `zip_kit_stream`, so that zip_kit checks the file names against the EPUB rules. An already
built book can be written into the same block with `book.write_epub(zip)`.

The response is underway by the time the block runs, so if building the book fails - for example because an
item has a file name which is not allowed in an EPUB - the download gets cut short rather than turning into
an error page.

Outside of Rails, `GEPUB::Book.rack_body { |book| ... }` and `book.to_rack_body` return a Rack response body.

## INSTALL:

* gem install gepub

## DONATE:

* Bitcoin Address: `1M69AwoxpgPZsp5KStLUEjP7so5dHVfDTH`
