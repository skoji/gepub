# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'

describe GEPUB::Manifest do
  context 'parse existing opf' do
    before do
      @manifest = GEPUB::PackageData.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test.opf'), '/package.opf').instance_eval{ @manifest }
    end

    it 'should be parsed' do
      @manifest.item_list.size.should == 9
      @manifest.item_list['ncx'].href.should == 'toc.ncx'
      @manifest.item_list['ncx'].media_type.should == 'application/x-dtbncx+xml'
      @manifest.item_list['cover'].href.should == 'cover/cover.xhtml'
      @manifest.item_list['cover'].media_type.should == 'application/xhtml+xml'
      @manifest.item_list['cover-image'].href.should == 'img/cover.jpg'
      @manifest.item_list['cover-image'].media_type.should == 'image/jpeg'
      @manifest.item_list['cover-image'].properties[0].should == 'cover-image'
    end
  end
  context 'generate new opf' do
    it 'should generate xml' do
      manifest = GEPUB::Manifest.new
      manifest.add_item('ncx', 'toc.ncx', 'application/x-dtbncx+xml')
      builder = Nokogiri::XML::Builder.new { |xml|
        xml.package('xmlns' => "http://www.idpf.org/2007/opf",'version' => "3.0",'unique-identifier' => "pub-id",'xml:lang' => "ja") {
          manifest.to_xml(xml)
        }
      }
      xml = Nokogiri::XML::Document.parse(builder.to_xml)
      puts builder.to_xml
      xml.xpath("//xmlns:item[@id='ncx' and @href='toc.ncx' and @media-type='application/x-dtbncx+xml']").size.should == 1
    end
  end
end
