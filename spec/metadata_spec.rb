require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'

describe GEPUB::Metadata do
  it 'should be initialized' do
    metadata = GEPUB::Metadata.new
    metadata.opf_version.should == '3.0'
    metadata.prefix(GEPUB::XMLUtil::DC_NS).should == 'xmlns:dc'
    metadata.prefix(GEPUB::XMLUtil::OPF_NS).should be_nil
  end
  it 'should be initialized with version 2.0' do
    metadata = GEPUB::Metadata.new('2.0')
    metadata.opf_version.should == '2.0'
    metadata.prefix(GEPUB::XMLUtil::DC_NS).should == 'xmlns:dc'
    metadata.prefix(GEPUB::XMLUtil::OPF_NS).should == 'xmlns:opf'
  end
end
