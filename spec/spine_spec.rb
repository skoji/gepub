# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'

describe GEPUB::Spine do
  context 'parse existing opf' do
    before do
      @spine = GEPUB::PackageData.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test.opf'), '/package.opf').instance_eval{ @spine }
    end
    it 'should be parsed' do
      @spine.toc.should == 'ncx'
      @spine.page_progression_direction == 'ltr'
      @spine.itemref_list.size.should == 4
      @spine.itemref_list[0].idref.should == 'cover'
      @spine.itemref_list[0].linear.should == 'no'
      @spine.itemref_list[1].idref.should == 'toc'
      @spine.itemref_list[1].linear.should == 'yes'
      @spine.itemref_list[2].idref.should == 'chap1'
      @spine.itemref_list[2].linear.should == 'yes'
      @spine.itemref_list[3].idref.should == 'nav'
      @spine.itemref_list[3].linear.should == 'no'
    end
  end
end
