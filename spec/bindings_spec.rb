# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'

describe GEPUB::Bindings do
  context 'parse existing opf' do
    before do
      @bindings = GEPUB::Package.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test_with_bindings.opf'), '/package.opf').instance_eval{ @bindings }
    end
    it 'should be parsed' do
      expect(@bindings.media_types.size).to eq(2)
      expect(@bindings.media_types[0].handler).to eq('h')
      expect(@bindings.media_types[0].media_type).to eq('application/x-foreign-type')
      expect(@bindings.media_types[1].handler).to eq('v')
      expect(@bindings.media_types[1].media_type).to eq('application/x-other-foreign-type')
    end
  end
  
  context 'generate new opf' do
    it 'should generate xml' do
      bindings = GEPUB::Bindings.new
      bindings.add('id1', 'application/x-some-type')
      builder = Nokogiri::XML::Builder.new { |xml|
        xml.package('xmlns' => "http://www.idpf.org/2007/opf",'version' => "3.0",'unique-identifier' => "pub-id",'xml:lang' => "ja") {
          bindings.to_xml(xml)
        }
      }
      xml = Nokogiri::XML::Document.parse(builder.to_xml)
      expect(xml.xpath("//xmlns:mediaType[@handler='id1' and @media-type='application/x-some-type']").size).to eq(1)
    end
  end
  
end
