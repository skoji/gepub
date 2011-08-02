# need to install 'epubcheck'.

require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'

describe GEPUB::Item do
  it "should return atttributes" do
    item = GEPUB::Item.new('theid', 'foo/bar.bar', 'application/xhtml+xml')
    item.itemid.should == 'theid'
    item.href.should == 'foo/bar.bar'
    item.mediatype.should == 'application/xhtml+xml'
  end

  it "should handle html" do
    item = GEPUB::Item.new('id', 'text/foo.html')
    item.mediatype.should == 'application/xhtml+xml'
  end

  it "should handle xhtml" do
    item = GEPUB::Item.new('id', 'text/foo.xhtml')
    item.mediatype.should == 'application/xhtml+xml'
  end

  it "should handle JPG" do
    item = GEPUB::Item.new('id', 'img/foo.JPG')
    item.mediatype.should == 'image/jpeg'
  end

end

describe GEPUB::Book do
  before do
    @book = GEPUB::Book.new('thetitle')
    @book.author = "theauthor"
    @book.contributor = "contributors contributors!"
    @book.publisher = "thepublisher"
    @book.date = "2010-05-05"
    @book.identifier = "http://example.jp/foobar/"
    @book.locale = 'ja'
    item1 = @book.add_ref_to_item('text/foobar.html','c1')
    item1.add_content(StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c1</title></head><body><p>the first page</p></body></html>'))
    @book.spine.push(item1)

    item2 = @book.add_ordered_item('text/barbar.html',
                                        StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c2</title></head><body><p>second page, whith is test chapter.</p></body></html>'),
                                        'c2')
    @book.add_nav(item2, 'test chapter')
  end

  it "should have titile"  do
    @book.title.should == 'thetitle' 
  end

  it "should generate correct ncx"  do
    ncx = Nokogiri::XML.parse(@book.ncx_xml).root
    ncx.name.should == 'ncx'
    ncx.attributes['version'].value.should == '2005-1'
    ncx.namespaces['xmlns'] == 'http://www.daisy.org/z3986/2005/ncx/'
  end

  it "should have correct head in ncx" do
    head = Nokogiri::XML.parse(@book.ncx_xml).at_xpath('/xmlns:ncx/xmlns:head')
    head.should_not be_nil
    head.at_xpath("xmlns:meta[@name='dtb:uid']")['content'].should == "http://example.jp/foobar/"
    head.xpath("xmlns:meta[@name='dtb:depth']").size.should > 0
    head.xpath("xmlns:meta[@name='dtb:totalPageCount']").size.should > 0
    head.xpath("xmlns:meta[@name='dtb:maxPageNumber']").size.should > 0
  end

  it "should have correct ncx doctitle" do
    doctitle = Nokogiri::XML.parse(@book.ncx_xml).root

    doctitle.xpath('xmlns:docTitle').size.should > 0 
    doctitle.at_xpath('xmlns:docTitle/xmlns:text').text.should == 'thetitle'
  end

  it "should correct ncx navmap" do
    ncx = Nokogiri::XML::parse(@book.ncx_xml).root

    ncx.xpath('xmlns:navMap').size.should > 0
    nav_point = ncx.at_xpath('xmlns:navMap/xmlns:navPoint')
    nav_point['id'].should == 'c2'
    nav_point['playOrder'].should == '1'
    
    nav_point.at_xpath('xmlns:navLabel/xmlns:text').content.should == 'test chapter'
    nav_point.at_xpath('xmlns:content')['src'] == 'foobar2.html'

  end

  it "should create correct opf" do
    opf = Nokogiri::XML.parse(@book.opf_xml).root
    opf.name.should == 'package'
    opf.namespaces['xmlns'] == 'http://www.idpf.org/2007/opf'
    opf['version'] == '2.0'
    opf['unique-identifier'] == 'http://example.jp/foobar/'
  end

  it "should have correct metadata in opf" do
    opf = Nokogiri::XML.parse(@book.opf_xml).root
    metadata = opf.xpath('xmlns:metadata').first
    metadata.at_xpath('dc:language', metadata.namespaces).content.should == 'ja'
    #TODO: check metadata
  end

  it "should have correct manifest and spine in opf" do
    opf = Nokogiri::XML.parse(@book.opf_xml).root

    manifest = opf.at_xpath('xmlns:manifest')
    manifest.at_xpath('xmlns:item')['id'].should == 'c1'
    manifest.at_xpath('xmlns:item')['href'].should == 'text/foobar.html'    
    manifest.at_xpath('xmlns:item')['media-type'].should == 'application/xhtml+xml'

    spine = opf.at_xpath('xmlns:spine')
    spine['toc'].should == 'ncx'
    spine.at_xpath('xmlns:itemref')['idref'].should == 'c1'
  end

  it "should have correct cover image id" do
    item = @book.add_ref_to_item("img/img.jpg")
    @book.specify_cover_image(item)

    opf = Nokogiri::XML.parse(@book.opf_xml).root

    metadata = opf.at_xpath('xmlns:metadata')
    meta = metadata.at_xpath("xmlns:meta[@name='cover']")
    meta['content'].should == item.itemid        
  end

  it "should generate correct epub" do
    epubname = File.join(File.dirname(__FILE__), 'testepub.epub')
    @book.generate_epub(epubname)
    %x( epubcheck #{epubname} )
  end

end
