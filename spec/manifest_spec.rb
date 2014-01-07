# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'

describe GEPUB::Manifest do
  context 'parse existing opf' do
    before do
      @manifest = GEPUB::Package.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test.opf'), '/package.opf').instance_eval{ @manifest }
    end

    it 'should be parsed' do
      expect(@manifest.item_list.size).to eq(9)
      expect(@manifest.item_list['ncx'].href).to eq('toc.ncx')
      expect(@manifest.item_list['ncx'].media_type).to eq('application/x-dtbncx+xml')
      expect(@manifest.item_list['cover'].href).to eq('cover/cover.xhtml')
      expect(@manifest.item_list['cover'].media_type).to eq('application/xhtml+xml')
      expect(@manifest.item_list['cover-image'].href).to eq('img/cover.jpg')
      expect(@manifest.item_list['cover-image'].media_type).to eq('image/jpeg')
      expect(@manifest.item_list['cover-image'].properties[0]).to eq('cover-image')
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
      expect(xml.xpath("//xmlns:item[@id='ncx' and @href='toc.ncx' and @media-type='application/x-dtbncx+xml']").size).to eq(1)
    end
  end
end
