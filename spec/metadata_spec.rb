require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'

describe GEPUB::Metadata do
  it 'should be initialized' do
    metadata = GEPUB::Metadata.new
    metadata.prefix(GEPUB::XMLUtil::DC_NS).should == 'dc'
    metadata.prefix(GEPUB::XMLUtil::OPF_NS).should be_nil
  end
  it 'should be initialized with version 2.0' do
    metadata = GEPUB::Metadata.new('2.0')
    metadata.prefix(GEPUB::XMLUtil::DC_NS).should == 'dc'
    metadata.prefix(GEPUB::XMLUtil::OPF_NS).should == 'opf'
  end
  context 'Parse Existing OPF' do
    before do
      @metadata = GEPUB::PackageData.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test.opf'), '/package.opf').instance_eval{ @metadata }
    end
    it 'should parse title' do
      @metadata.main_title.should == 'TheTitle'
      @metadata.titles.size.should == 2
    end
    
    it 'should parse title-type' do
      @metadata.titles[0].refiner('title-type').size.should == 1
      @metadata.titles[0].refiner('title-type')[0].content.should == 'main'
      @metadata.titles[1].refiner('title-type').size.should == 1
      @metadata.titles[1].refiner('title-type')[0].content.should == 'collection'
    end

    it 'should parse identifier' do
      @metadata.identifiers.size.should == 2
      @metadata.identifiers[0].content.should == 'urn:uuid:1234567890'
      @metadata.identifiers[0].first_refiner('identifier-type').content.should == 'uuid'
      @metadata.identifiers[1].content.should == 'http://example.jp/epub/test/url'
      @metadata.identifiers[1].first_refiner('identifier-type').content.should == 'uri'
    end

    it 'should parse OPF2.0 meta node' do
      @metadata.other_nodes.size.should == 1
      @metadata.other_nodes[0].name == 'meta'
      @metadata.other_nodes[0]['name'] == 'cover'
      @metadata.other_nodes[0]['content'] == 'cover-image'
    end
  end
end
