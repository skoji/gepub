# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'

describe GEPUB::Package do
  it 'should be initialized' do
    opf = GEPUB::Package.new('/package.opf')
    expect(opf.ns_prefix(GEPUB::XMLUtil::OPF_NS)).to eq('xmlns')
  end

  context 'parse existing opf' do
    it 'should be initialized with opf' do
      opf = GEPUB::Package.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test.opf'), '/package.opf')
      expect(opf.ns_prefix(GEPUB::XMLUtil::OPF_NS)).to eq('xmlns')
      expect(opf['version']).to eq('3.0')
      expect(opf['unique-identifier']).to eq('pub-id')
      expect(opf['xml:lang']).to eq('ja')
      expect(opf['prefix']).to eq('foaf: http://xmlns.com/foaf/spec/                   rendition:  http://www.idpf.org/vocab/rendition/#')
    end
    it 'should parse prefix data' do
      package = GEPUB::Package.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test.opf'), '/package.opf')
      expect(package.prefixes.size).to eq(2)
      expect(package.prefixes['foaf']).to eq('http://xmlns.com/foaf/spec/')
      expect(package.prefixes['rendition']).to eq('http://www.idpf.org/vocab/rendition/#')
      
    end

    it 'should parse rendition metadata' do
      package = GEPUB::Package.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test.opf'), '/package.opf')
      expect(package.rendition_layout).to eq('pre-paginated')
      expect(package.rendition_orientation).to eq('auto')
      expect(package.rendition_spread).to eq('both')
      
    end

  end
  context 'generate new opf' do
    it 'should generate opf' do
      opf = GEPUB::Package.new('OEBPS/package.package') {
        |package|
        package.primary_identifier('http://example.jp', 'BookID', 'url')
        package['xml:lang'] = 'ja'

        # metadata add: style 1
        package.metadata.add_title('EPUB3 Sample', nil, GEPUB::TITLE_TYPE::MAIN) {
          |title|
          title.display_seq = 1
          title.file_as = 'Sample EPUB3'
          title.add_alternates(
                               'en' => 'EPUB3 Sample (Japanese)',
                               'el' => 'EPUB3 δείγμα (Ιαπωνικά)',
                               'th' => 'EPUB3 ตัวอย่าง (ญี่ปุ่น)')
        }
        # metadata add: style2
        package.metadata.add_title('これでEPUB3もばっちり', nil, GEPUB::TITLE_TYPE::SUBTITLE).display_seq(2).add_alternates('en' => 'you need nothing but this book!')
        package.metadata.add_creator('小嶋智').display_seq(1).add_alternates('en' => 'KOJIMA Satoshi')
        package.metadata.add_contributor('電書部').display_seq(1).add_alternates('en' => 'Denshobu')
        package.metadata.add_contributor('アサガヤデンショ').display_seq(2).add_alternates('en' => 'Asagaya Densho')
        package.metadata.add_contributor('湘南電書鼎談').display_seq(3).add_alternates('en' => 'Shonan Densho Teidan')
        package.metadata.add_contributor('電子雑誌トルタル').display_seq(4).add_alternates('en' => 'eMagazine Torutaru')
        package.add_item('img/image1.jpg')
        package.add_item('img/cover.jpg').add_property('cover-image')
        package.ordered {
          package.add_item('text/chapter1.xhtml')
          package.add_item('text/chapter2.xhtml')
        }
      }
      xml = Nokogiri::XML::Document.parse opf.opf_xml
      expect(xml.root.name).to eq('package')
      expect(xml.root.namespaces.size).to eq(1)
      expect(xml.root.namespaces['xmlns']).to eq(GEPUB::XMLUtil::OPF_NS)
      expect(xml.root['version']).to eq('3.0')
      expect(xml.root['xml:lang']).to eq('ja')
      # TODO: should check all elements
    end

    it 'should generate package with prefix attribute' do
      opf = GEPUB::Package.new('OEBPS/package.opf') do
        |package|
        package.primary_identifier('http://example.jp', 'BookID', 'url')
        package['xml:lang'] = 'ja'
        package.enable_rendition
      end
      xml = Nokogiri::XML::Document.parse opf.opf_xml
      expect(xml.root['prefix']).to eq('rendition: http://www.idpf.org/vocab/rendition/#')
    end

    it 'should generate package with rendition attributes' do
      opf = GEPUB::Package.new('OEBPS/package.opf') do
        |package|
        package.rendition_layout = 'pre-paginated'
        package.rendition_orientation = 'portlait'
        package.rendition_spread = 'landscape'
      end
      xml = Nokogiri::XML::Document.parse opf.opf_xml
      expect(xml.root['prefix']).to eq('rendition: http://www.idpf.org/vocab/rendition/#')
      expect(xml.at_xpath("//xmlns:meta[@property='rendition:layout']").content).to eq('pre-paginated')
      expect(xml.at_xpath("//xmlns:meta[@property='rendition:orientation']").content).to eq('portlait')
      expect(xml.at_xpath("//xmlns:meta[@property='rendition:spread']").content).to eq('landscape')
    end

    it 'should handle ibooks version' do
      opf = GEPUB::Package.new('OEBPS/package.opf') do
        |package|
        package.ibooks_version = '1.1.1'
      end
      xml = Nokogiri::XML::Document.parse opf.opf_xml
      expect(xml.root['prefix']).to eq('ibooks: http://vocabulary.itunes.apple.com/rdf/ibooks/vocabulary-extensions-1.0/')
      expect(xml.at_xpath("//xmlns:meta[@property='ibooks:version']").content).to eq('1.1.1')
    end
    
    it 'should generate opf2.0' do
      opf = GEPUB::Package.new('OEBPS/package.opf', { 'version' => '2.0'}) {
        |package|
        package.primary_identifier('http://example.jp', 'BookID', 'url')
        package['xml:lang'] = 'ja'

        # metadata add: style 1
        package.metadata.add_title('EPUB3 Sample', nil, GEPUB::TITLE_TYPE::MAIN) {
          |title|
          title.display_seq = 1
          title.file_as = 'Sample EPUB3'
          title.add_alternates(
                               'en' => 'EPUB3 Sample (Japanese)',
                               'el' => 'EPUB3 δείγμα (Ιαπωνικά)',
                               'th' => 'EPUB3 ตัวอย่าง (ญี่ปุ่น)')
        }
        # metadata add: style2
        package.metadata.add_title('これでEPUB3もばっちり', nil, GEPUB::TITLE_TYPE::SUBTITLE).display_seq(2).add_alternates('en' => 'you need nothing but this book!')
        package.metadata.add_creator('小嶋智').display_seq(1).add_alternates('en' => 'KOJIMA Satoshi')
        package.metadata.add_contributor('電書部').display_seq(1).add_alternates('en' => 'Denshobu')
        package.metadata.add_contributor('アサガヤデンショ').display_seq(2).add_alternates('en' => 'Asagaya Densho')
        package.metadata.add_contributor('湘南電書鼎談').display_seq(3).add_alternates('en' => 'Shonan Densho Teidan')
        package.metadata.add_contributor('電子雑誌トルタル').display_seq(4).add_alternates('en' => 'eMagazine Torutaru')
        package.add_item('img/image1.jpg')
        package.ordered {
          package.add_item('text/chapter1.xhtml')
          package.add_item('text/chapter2.xhtml')
        }
      }
      xml = Nokogiri::XML::Document.parse opf.opf_xml
      expect(xml.root.name).to eq('package')
      expect(xml.root.namespaces.size).to eq(1)
      expect(xml.root.namespaces['xmlns']).to eq(GEPUB::XMLUtil::OPF_NS)
      expect(xml.root['version']).to eq('2.0')
      expect(xml.root['xml:lang']).to eq('ja')
    end
  end
end
