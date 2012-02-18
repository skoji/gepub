require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'

describe GEPUB::PackageData do
  it 'should be initialized' do
    opf = GEPUB::PackageData.new('/package.opf')
    opf.ns_prefix(GEPUB::XMLUtil::OPF_NS).should == 'xmlns'
  end
  it 'should be initialized with opf' do
    opf = GEPUB::PackageData.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test.opf'), '/package.opf')
    opf.ns_prefix(GEPUB::XMLUtil::OPF_NS).should == 'xmlns'
    opf['version'].should == '3.0'
    opf['unique-identifier'].should == 'pub-id'
    opf['xml:lang'].should == 'ja'
  end
end
