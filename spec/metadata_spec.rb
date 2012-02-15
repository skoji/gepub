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
      @metadata.title.size.should == 2
    end
    
    it 'should parse title-type' do
      @metadata.title[0].refiner('title-type').size.should == 1
      @metadata.title[0].refiner('title-type')[0].content.should == 'main'
      @metadata.title[1].refiner('title-type').size.should == 1
      @metadata.title[1].refiner('title-type')[0].content.should == 'collection'
    end


  end
end
