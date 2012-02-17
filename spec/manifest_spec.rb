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
      @manifest.item_list[0].id.should == 'ncx'
      @manifest.item_list[0].href.should == 'toc.ncx'
      @manifest.item_list[0].media_type.should == 'application/x-dtbncx+xml'
      @manifest.item_list[1].id.should == 'cover'
      @manifest.item_list[1].href.should == 'cover/cover.xhtml'
      @manifest.item_list[1].media_type.should == 'application/xhtml+xml'
      @manifest.item_list[2].id.should == 'cover-image'
      @manifest.item_list[2].href.should == 'img/cover.jpg'
      @manifest.item_list[2].media_type.should == 'image/jpeg'
      @manifest.item_list[2].properties[0].should == 'cover-image'
    end
    
  end
end
