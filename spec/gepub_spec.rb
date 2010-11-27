# need to install 'epubcheck'.

require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'xml/libxml'


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
    @generator = GEPUB::Book.new('thetitle')
    @generator.author = "theauthor"
    @generator.contributor = "contributors contributors!"
    @generator.publisher = "thepublisher"
    @generator.date = "2010-05-05"
    @generator.identifier = "http://example.jp/foobar/"
    item1 = @generator.add_ref_to_item('text/foobar.html','c1')
    item1.add_content(StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c1</title></head><body><p>the first page</p></body></html>'))
    @generator.spine.push(item1)

    item2 = @generator.add_ordered_item('text/barbar.html',
                                        StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c2</title></head><body><p>second page, whith is test chapter.</p></body></html>'),
                                        'c2')
    @generator.add_nav(item2, 'test chapter')
  end

  it "should have titile"  do
    @generator.title.should == 'thetitle' 
  end

  it "should generate correct ncx"  do
    ncx = LibXML::XML::Parser.string(@generator.ncx_xml).parse
    ncx.root.name.should == 'ncx'
    ncx.root.attributes['version'].should == '2005-1'
    ncx.root.namespaces.namespace.href.should == 'http://www.daisy.org/z3986/2005/ncx/'
  end

  it "should have correct head in ncx" do
    ncx = LibXML::XML::Parser.string(@generator.ncx_xml).parse
    ncx.root.namespaces.default_prefix='a'

    ncx.find_first('a:head').should_not be_nil

    ncx.find_first("a:head/a:meta[@name='dtb:uid']")['content'].should == "http://example.jp/foobar/"
    ncx.find_first("a:head/a:meta[@name='dtb:depth']").should_not be_nil
    ncx.find_first("a:head/a:meta[@name='dtb:totalPageCount']").should_not be_nil
    ncx.find_first("a:head/a:meta[@name='dtb:maxPageNumber']").should_not be_nil
  end

  it "should have correct ncx doctitle" do
    ncx = LibXML::XML::Parser.string(@generator.ncx_xml).parse
    ncx.root.namespaces.default_prefix='a'

    ncx.root.find_first('a:docTitle').should_not be_nil
    ncx.root.find_first('a:docTitle/a:text').content.should == 'thetitle'
  end

  it "should correct ncx navmap" do
    ncx = LibXML::XML::Parser.string(@generator.ncx_xml).parse
    ncx.root.namespaces.default_prefix='a'

    ncx.root.find_first('a:navMap').should_not be_nil
    nav_point = ncx.root.find_first('a:navMap/a:navPoint')
    nav_point['id'].should == 'c2'
    nav_point['playOrder'].should == '1'
    
    nav_point.find_first('a:navLabel/a:text').content.should == 'test chapter'
    nav_point.find_first('a:content')['src'] == 'foobar2.html'

  end

  it "should create correct opf" do
    opf = LibXML::XML::Parser.string(@generator.opf_xml).parse
    opf.root.namespaces.default_prefix='a'

    opf.root.name.should == 'package'
    opf.root.namespaces.namespace.href.should == 'http://www.idpf.org/2007/opf'
    opf.root['version'] == '2.0'
    opf.root['unique-identifier'] == 'http://example.jp/foobar/'
  end
  

  it "should have correct metadata in opf" do
    opf = LibXML::XML::Parser.string(@generator.opf_xml).parse
    opf.root.namespaces.default_prefix='a'

    metadata = opf.find_first('a:metadata')
    metadata.find_first('dc:language').content.should == 'ja'
    # TODO checking metadatas...
  end

  it "should have correct manifest and spine in opf" do
    opf = LibXML::XML::Parser.string(@generator.opf_xml).parse
    opf.root.namespaces.default_prefix='a'

    manifest = opf.find_first('a:manifest')
    manifest.find_first('a:item')['id'].should == 'c1'
    manifest.find_first('a:item')['href'].should == 'text/foobar.html'    
    manifest.find_first('a:item')['media-type'].should == 'application/xhtml+xml'

    spine = opf.find_first('a:spine')
    spine['toc'].should == 'ncx'
    spine.find_first('a:itemref')['idref'].should == 'c1'
  end

  it "should have correct metadata in opf" do
    opf = LibXML::XML::Parser.string(@generator.opf_xml).parse
    opf.root.namespaces.default_prefix='a'

    metadata = opf.find_first('a:metadata')
    metadata.find_first('dc:language').content.should == 'ja'
    # TODO checking metadatas...
  end

  it "should have correct cover image id" do
    item = @generator.add_ref_to_item("img/img.jpg")
    @generator.specify_cover_image(item)

    opf = LibXML::XML::Parser.string(@generator.opf_xml).parse
    opf.root.namespaces.default_prefix='a'

    metadata = opf.find_first('a:metadata')
    metas = metadata.find('a:meta').select {
      |m| m['name'] == 'cover'
    }
    metas.length.should == 1
    metas[0]['content'].should == item.itemid    
  end

  it "should generate correct epub" do
    epubname = File.join(File.dirname(__FILE__), 'testepub.epub')
    @generator.generate_epub(epubname)
    %x( epubcheck #{epubname} )
  end

end
