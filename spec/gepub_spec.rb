require File.dirname(__FILE__) + '/spec_helper.rb'

require 'rubygems'
require 'xml/libxml'

# for parsing only elements. DO I REALLY NEED THIS !?
class LibXML::XML::Node
  def next_element
    r = self.next
    r = r.next while !r.element?
    r            
  end

  def first_child_element
    r = self.first
    r = r.next_element if !r.element?
    r
  end
end


describe GEPUB::Generator do
  before do
    @generator = GEPUB::Generator.new('thetitle')
    @generator.author = "theauthor"
    @generator.publisher = "thepublisher"
    @generator.date = "2010-05-05"
    @generator.identifier = "http://example.jp/foobar/"

    @generator.addManifest('c1', 'foobar.html', 'foo/bar')
    @generator.addNav('c2', 'test chapter', 'foobar2.html')
    @generator.spine.push('c1')
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
    manifest.find_first('a:item')['href'].should == 'foobar.html'    
    manifest.find_first('a:item')['media-type'].should == 'foo/bar'

    spine = opf.find_first('a:spine')
    spine['toc'].should == 'ncx'
    spine.find_first('a:itemref')['idref'].should == 'c1'
  end
  
end
