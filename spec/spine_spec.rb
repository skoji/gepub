# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'

describe GEPUB::Spine do
  context 'parse existing opf' do
    before do
      @spine = GEPUB::Package.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test.opf'), '/package.opf').instance_eval{ @spine }
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
  context 'generate new opf' do
    it 'should generate xml' do
      spine = GEPUB::Spine.new
      spine.toc = 'ncx'
      spine.push(GEPUB::Item.new('the_id', 'OEBPS/foo.xhtml')).set_linear('no')
      builder = Nokogiri::XML::Builder.new { |xml|
        xml.package('xmlns' => "http://www.idpf.org/2007/opf",'version' => "3.0",'unique-identifier' => "pub-id",'xml:lang' => "ja") {
          spine.to_xml(xml)
        }
      }
      xml = Nokogiri::XML::Document.parse(builder.to_xml)
      xml.at_xpath('//xmlns:spine')['toc'].should == 'ncx'
      xml.xpath("//xmlns:itemref[@idref='the_id' and @linear='no']").size.should == 1
    end
    it 'should generate xml with property' do
      spine = GEPUB::Spine.new
      spine.toc = 'ncx'
      spine.push(GEPUB::Item.new('the_id', 'OEBPS/foo.xhtml')).page_spread_right
      builder = Nokogiri::XML::Builder.new { |xml|
        xml.package('xmlns' => "http://www.idpf.org/2007/opf",'version' => "3.0",'unique-identifier' => "pub-id",'xml:lang' => "ja") {
          spine.to_xml(xml)
        }
      }
      xml = Nokogiri::XML::Document.parse(builder.to_xml)
      xml.at_xpath('//xmlns:spine')['toc'].should == 'ncx'
      xml.xpath("//xmlns:itemref[@idref='the_id' and @properties='page-spread-right']").size.should == 1
    end

  end
  
end
