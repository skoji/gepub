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
      expect(@spine.toc).to eq('ncx')
      expect(@spine.page_progression_direction).to eq('ltr')
      expect(@spine.itemref_list.size).to eq(4)
      expect(@spine.itemref_list[0].idref).to eq('cover')
      expect(@spine.itemref_list[0].linear).to eq('no')
      expect(@spine.itemref_list[1].idref).to eq('toc')
      expect(@spine.itemref_list[1].linear).to eq('yes')
      expect(@spine.itemref_list[2].idref).to eq('chap1')
      expect(@spine.itemref_list[2].linear).to eq('yes')
      expect(@spine.itemref_list[3].idref).to eq('nav')
      expect(@spine.itemref_list[3].linear).to eq('no')
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
      expect(xml.at_xpath('//xmlns:spine')['toc']).to eq('ncx')
      expect(xml.xpath("//xmlns:itemref[@idref='the_id' and @linear='no']").size).to eq(1)
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
      expect(xml.at_xpath('//xmlns:spine')['toc']).to eq('ncx')
      expect(xml.xpath("//xmlns:itemref[@idref='the_id' and @properties='page-spread-right']").size).to eq(1)
    end

  end
  
end
