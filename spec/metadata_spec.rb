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
end
