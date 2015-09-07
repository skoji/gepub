# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'

describe GEPUB::Item do
  it "should return atttributes" do
    item = GEPUB::Item.new('theid', 'foo/bar.bar', 'application/xhtml+xml')
    expect(item.itemid).to eq('theid')
    expect(item.href).to eq('foo/bar.bar')
    expect(item.mediatype).to eq('application/xhtml+xml')
  end

  it "should handle html" do
    item = GEPUB::Item.new('id', 'text/foo.html')
    expect(item.mediatype).to eq('application/xhtml+xml')
  end

  it "should handle xhtml" do
    item = GEPUB::Item.new('id', 'text/foo.xhtml')
    expect(item.mediatype).to eq('application/xhtml+xml')
  end

  it "should handle JPG" do
    item = GEPUB::Item.new('id', 'img/foo.JPG')
    expect(item.mediatype).to eq('image/jpeg')
  end

  it "should handle css" do
    item = GEPUB::Item.new('id', 'img/foo.css')
    expect(item.mediatype).to eq('text/css')
  end

  it "should handle javascript" do
    item = GEPUB::Item.new('id', 'js/jQuery.js')
    expect(item.mediatype).to eq('text/javascript')
  end

end

describe GEPUB::Book do
  before do
    @book = GEPUB::Book.new('OEPBS/package.opf') 
    @book.title = 'thetitle'
    @book.creator = "theauthor"
    @book.contributor = "contributors contributors!"
    @book.publisher = "thepublisher"
    @book.date = "2010-05-05"
    @book.identifier = "http://example.jp/foobar/"
    @book.language = 'ja'
    item1 = @book.add_item('text/foobar.xhtml',nil, 'c1')
    item1.add_content(StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c1</title></head><body><p>the first page</p></body></html>'))
    @book.spine.push(item1)

    item2 = @book.add_ordered_item('text/barbar.xhtml',
                                   StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c2</title></head><body><p>second page, whith is test chapter.</p></body></html>'),
                                   'c2')
    item2.toc_text 'test chapter'

    item3 = @book.add_item('text/handler.xhtml',
                           StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c2</title><script>alert("foo");</script></head><body><p>this is scripted item</p></body></html>')
                           )
    item3.add_property('scripted')
    item3.is_handler_of('application/x-some-media-type')
    @item3_id = item3.id

    nav_string = <<EOF
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head></head>
<body>
<nav epub:type="toc" id="toc">
  <h1>Table of contents</h1>
  <ol>
    <li><a href="foobar.xhtml">Chapter 1</a> </li>
    <li> <a href="barbar.xhtml">Chapter 2</a></li>
  </ol>
</nav>
</body>
</html>
EOF
    item3 = @book.add_ordered_item('text/nav.xhtml', StringIO.new(nav_string), 'nav').add_property('nav')
  end

  it "should have titile"  do
    expect(@book.title.to_s).to eq('thetitle') 
  end

  it "should generate correct ncx"  do
    ncx = Nokogiri::XML.parse(@book.ncx_xml).root
    expect(ncx.name).to eq('ncx')
    expect(ncx.attributes['version'].value).to eq('2005-1')
    ncx.namespaces['xmlns'] == 'http://www.daisy.org/z3986/2005/ncx/'
  end

  it "should have correct head in ncx" do
    head = Nokogiri::XML.parse(@book.ncx_xml).at_xpath('/xmlns:ncx/xmlns:head')
    expect(head).not_to be_nil
    expect(head.at_xpath("xmlns:meta[@name='dtb:uid']")['content']).to eq("http://example.jp/foobar/")
    expect(head.xpath("xmlns:meta[@name='dtb:depth']").size).to be > 0
    expect(head.xpath("xmlns:meta[@name='dtb:totalPageCount']").size).to be > 0
    expect(head.xpath("xmlns:meta[@name='dtb:maxPageNumber']").size).to be > 0
  end

  it "should have correct ncx doctitle" do
    doctitle = Nokogiri::XML.parse(@book.ncx_xml).root

    expect(doctitle.xpath('xmlns:docTitle').size).to be > 0 
    expect(doctitle.at_xpath('xmlns:docTitle/xmlns:text').text).to eq('thetitle')
  end

  it "should correct ncx navmap" do
    ncx = Nokogiri::XML::parse(@book.ncx_xml).root

    expect(ncx.xpath('xmlns:navMap').size).to be > 0
    nav_point = ncx.at_xpath('xmlns:navMap/xmlns:navPoint')
    expect(nav_point['id']).to eq('c2_')
    expect(nav_point['playOrder']).to eq('1')
    
    expect(nav_point.at_xpath('xmlns:navLabel/xmlns:text').content).to eq('test chapter')
    nav_point.at_xpath('xmlns:content')['src'] == 'foobar2.html'

  end

  it "should create correct opf" do
    opf = Nokogiri::XML.parse(@book.opf_xml).root
    expect(opf.name).to eq('package')
    expect(opf.namespaces['xmlns']).to eq('http://www.idpf.org/2007/opf')
    expect(opf['version']).to eq('3.0')
    expect(opf['unique-identifier']).to eq('BookId')
  end

  it "should have correct metadata in opf" do
    opf = Nokogiri::XML.parse(@book.opf_xml).root
    metadata = opf.xpath('xmlns:metadata').first
    expect(metadata.at_xpath('dc:language', metadata.namespaces).content).to eq('ja')
    #TODO: check metadata
  end

  it "should have correct manifest and spine in opf" do
    opf = Nokogiri::XML.parse(@book.opf_xml).root

    manifest = opf.at_xpath('xmlns:manifest')
    expect(manifest.at_xpath('xmlns:item[@id="c1"]')['href']).to eq('text/foobar.xhtml')    
    expect(manifest.at_xpath('xmlns:item[@id="c1"]')['media-type']).to eq('application/xhtml+xml')

    spine = opf.at_xpath('xmlns:spine')
    expect(spine['toc']).to eq('ncx')
    expect(spine.at_xpath('xmlns:itemref')['idref']).to eq('c1')
  end

  it "should have correct bindings in opf" do
    opf = Nokogiri::XML.parse(@book.opf_xml).root
    bindings = opf.at_xpath('xmlns:bindings')
    expect(bindings.at_xpath('xmlns:mediaType')['handler']).to eq(@item3_id)
    expect(bindings.at_xpath('xmlns:mediaType')['media-type']).to eq('application/x-some-media-type')
  end
  
  it "should have correct cover image id" do
    item = @book.add_item("img/img.jpg").cover_image

    opf = Nokogiri::XML.parse(@book.opf_xml).root

    metadata = opf.at_xpath('xmlns:metadata')
    meta = metadata.at_xpath("xmlns:meta[@name='cover']")
    expect(meta['content']).to eq(item.itemid)        
  end

  it "should generate correct epub" do
    epubname = File.join(File.dirname(__FILE__), 'testepub.epub')
    @book.generate_epub(epubname)
    epubcheck(epubname)
  end
  it "should generate correct epub with buffer" do
    epubname = File.join(File.dirname(__FILE__), 'testepub_buf.epub')
    File.open(epubname, 'wb') {
      |io|
      io.write @book.generate_epub_stream.string
    }
    epubcheck(epubname)
  end

  it "should generate correct epub2.0" do
    epubname = File.join(File.dirname(__FILE__), 'testepub2.epub')
    @book = GEPUB::Book.new('OEPBS/package.opf', { 'version' => '2.0'} ) 
    @book.title = 'thetitle'
    @book.creator = "theauthor"
    @book.contributor = "contributors contributors!"
    @book.publisher = "thepublisher"
    @book.date = "2010-05-05"
    @book.identifier = "http://example.jp/foobar/"
    @book.language = 'ja'
    item1 = @book.add_item('text/foobar.xhtml',nil, 'c1')
    item1.add_content(StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c1</title></head><body><p>the first page</p></body></html>'))
    @book.spine.push(item1)
    item2 = @book.add_ordered_item('text/barbar.xhtml',
                                   StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c2</title></head><body><p>second page, whith is test chapter.</p></body></html>'),
                                   'c2')
    item2.toc_text 'test chapter'
    @book.generate_epub(epubname)
    epubcheck(epubname)
  end
  it 'should generate epub with extra file' do
    epubname = File.join(File.dirname(__FILE__), 'testepub3.epub')
    @book.add_optional_file('META-INF/foobar.xml', StringIO.new('<foo></foo>'))
    @book.generate_epub(epubname)
    epubcheck(epubname)
  end

  it 'should generate valid EPUB when @toc is empty' do
    epubname = File.join(File.dirname(__FILE__), 'testepub4.epub')
    @book = GEPUB::Book.new('OEPBS/package.opf', { 'version' => '3.0'} ) 
    @book.title = 'thetitle'
    @book.creator = "theauthor"
    @book.contributor = "contributors contributors!"
    @book.publisher = "thepublisher"
    @book.date = "2015-05-05"
    @book.identifier = "http://example.jp/foobar/"
    @book.language = 'ja'
    item1 = @book.add_item('text/foobar.xhtml',nil, 'c1')
    item1.add_content(StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c1</title></head><body><p>the first page</p></body></html>'))
    @book.spine.push(item1)
    item2 = @book.add_ordered_item('text/barbar.xhtml',
                                   StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c2</title></head><body><p>second page, whith is test chapter.</p></body></html>'),
                                   'c2')
    @book.generate_epub(epubname)
    epubcheck(epubname)

  end
end
