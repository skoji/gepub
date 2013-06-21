# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'

describe GEPUB::Package do
  it 'should be initialized' do
    opf = GEPUB::Package.new('/package.opf')
    opf.ns_prefix(GEPUB::XMLUtil::OPF_NS).should == 'xmlns'
  end

  context 'parse existing opf' do
    it 'should be initialized with opf' do
      opf = GEPUB::Package.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test.opf'), '/package.opf')
      opf.ns_prefix(GEPUB::XMLUtil::OPF_NS).should == 'xmlns'
      opf['version'].should == '3.0'
      opf['unique-identifier'].should == 'pub-id'
      opf['xml:lang'].should == 'ja'
      opf['prefix'].should == 'foaf: http://xmlns.com/foaf/spec/                   rendition:  http://www.idpf.org/vocab/rendition/#'
    end
    it 'should parse prefix data' do
      package = GEPUB::Package.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test.opf'), '/package.opf')
      package.prefixes.size.should == 2
      package.prefixes['foaf'].should == 'http://xmlns.com/foaf/spec/'
      package.prefixes['rendition'].should == 'http://www.idpf.org/vocab/rendition/#'
      
    end

    it 'should parse rendition metadata' do
      package = GEPUB::Package.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test.opf'), '/package.opf')
      package.rendition_layout.should == 'pre-paginated'
      package.rendition_orientation.should == 'auto'
      package.rendition_spread.should == 'both'
      
    end

  end
  context 'generate new opf' do
    it 'should generate opf' do
      opf = GEPUB::Package.new('OEBPS/package.opf') {
        |opf|
        opf.set_main_id('http://example.jp', 'BookID', 'url')
        opf['xml:lang'] = 'ja'

        # metadata add: style 1
        opf.metadata.add_title('EPUB3 Sample', nil, GEPUB::TITLE_TYPE::MAIN) {
          |title|
          title.display_seq = 1
          title.file_as = 'Sample EPUB3'
          title.add_alternates(
                               'en' => 'EPUB3 Sample (Japanese)',
                               'el' => 'EPUB3 δείγμα (Ιαπωνικά)',
                               'th' => 'EPUB3 ตัวอย่าง (ญี่ปุ่น)')
        }
        # metadata add: style2
        opf.metadata.add_title('これでEPUB3もばっちり', nil, GEPUB::TITLE_TYPE::SUBTITLE).set_display_seq(2).add_alternates('en' => 'you need nothing but this book!')
        opf.metadata.add_creator('小嶋智').set_display_seq(1).add_alternates('en' => 'KOJIMA Satoshi')
        opf.metadata.add_contributor('電書部').set_display_seq(1).add_alternates('en' => 'Denshobu')
        opf.metadata.add_contributor('アサガヤデンショ').set_display_seq(2).add_alternates('en' => 'Asagaya Densho')
        opf.metadata.add_contributor('湘南電書鼎談').set_display_seq(3).add_alternates('en' => 'Shonan Densho Teidan')
        opf.metadata.add_contributor('電子雑誌トルタル').set_display_seq(4).add_alternates('en' => 'eMagazine Torutaru')
        opf.add_item('img/image1.jpg')
        opf.add_item('img/cover.jpg').add_property('cover-image')
        opf.ordered {
          opf.add_item('text/chapter1.xhtml')
          opf.add_item('text/chapter2.xhtml')
        }
      }
      xml = Nokogiri::XML::Document.parse opf.opf_xml
      xml.root.name.should == 'package'
      xml.root.namespaces.size.should == 1
      xml.root.namespaces['xmlns'].should == GEPUB::XMLUtil::OPF_NS
      xml.root['version'].should == '3.0'
      xml.root['xml:lang'].should == 'ja'
      # TODO: should check all elements
    end

    it 'should generate package with prefix attribute' do
      package = GEPUB::Package.new('OEBPS/package.opf') do
        |package|
        package.set_primary_identifier('http://example.jp', 'BookID', 'url')
        package['xml:lang'] = 'ja'
        package.enable_rendition
      end
      xml = Nokogiri::XML::Document.parse package.opf_xml
      xml.root['prefix'].should == 'rendition: http://www.idpf.org/vocab/rendition/#'
    end

    it 'should generate package with rendition attributes' do
      package = GEPUB::Package.new('OEBPS/package.opf') do
        |package|
        package.rendition_layout = 'pre-paginated'
        package.rendition_orientation = 'portlait'
        package.rendition_spread = 'landscape'
      end
      xml = Nokogiri::XML::Document.parse package.opf_xml
      xml.root['prefix'].should == 'rendition: http://www.idpf.org/vocab/rendition/#'
      xml.at_xpath("//xmlns:meta[@property='rendition:layout']").content.should == 'pre-paginated'
      xml.at_xpath("//xmlns:meta[@property='rendition:orientation']").content.should == 'portlait'
      xml.at_xpath("//xmlns:meta[@property='rendition:spread']").content.should == 'landscape'
    end

    it 'should handle ibooks version' do
      package = GEPUB::Package.new('OEBPS/package.opf') do
        |package|
        package.ibooks_version = '1.1.1'
      end
      xml = Nokogiri::XML::Document.parse package.opf_xml
      xml.root['prefix'].should == 'ibooks: http://vocabulary.itunes.apple.com/rdf/ibooks/vocabulary-extensions-1.0/'
      xml.at_xpath("//xmlns:meta[@property='ibooks:version']").content.should == '1.1.1'
    end
    
    it 'should generate opf2.0' do
      opf = GEPUB::Package.new('OEBPS/package.opf', { 'version' => '2.0'}) {
        |opf|
        opf.set_primary_identifier('http://example.jp', 'BookID', 'url')
        opf['xml:lang'] = 'ja'

        # metadata add: style 1
        opf.metadata.add_title('EPUB3 Sample', nil, GEPUB::TITLE_TYPE::MAIN) {
          |title|
          title.display_seq = 1
          title.file_as = 'Sample EPUB3'
          title.add_alternates(
                               'en' => 'EPUB3 Sample (Japanese)',
                               'el' => 'EPUB3 δείγμα (Ιαπωνικά)',
                               'th' => 'EPUB3 ตัวอย่าง (ญี่ปุ่น)')
        }
        # metadata add: style2
        opf.metadata.add_title('これでEPUB3もばっちり', nil, GEPUB::TITLE_TYPE::SUBTITLE).set_display_seq(2).add_alternates('en' => 'you need nothing but this book!')
        opf.metadata.add_creator('小嶋智').set_display_seq(1).add_alternates('en' => 'KOJIMA Satoshi')
        opf.metadata.add_contributor('電書部').set_display_seq(1).add_alternates('en' => 'Denshobu')
        opf.metadata.add_contributor('アサガヤデンショ').set_display_seq(2).add_alternates('en' => 'Asagaya Densho')
        opf.metadata.add_contributor('湘南電書鼎談').set_display_seq(3).add_alternates('en' => 'Shonan Densho Teidan')
        opf.metadata.add_contributor('電子雑誌トルタル').set_display_seq(4).add_alternates('en' => 'eMagazine Torutaru')
        opf.add_item('img/image1.jpg')
        opf.ordered {
          opf.add_item('text/chapter1.xhtml')
          opf.add_item('text/chapter2.xhtml')
        }
      }
      xml = Nokogiri::XML::Document.parse opf.opf_xml
      xml.root.name.should == 'package'
      xml.root.namespaces.size.should == 1
      xml.root.namespaces['xmlns'].should == GEPUB::XMLUtil::OPF_NS
      xml.root['version'].should == '2.0'
      xml.root['xml:lang'].should == 'ja'
    end
  end
end
