# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'

describe GEPUB::PackageData do
  it 'should be initialized' do
    opf = GEPUB::PackageData.new('/package.opf')
    opf.ns_prefix(GEPUB::XMLUtil::OPF_NS).should == 'xmlns'
  end
  context 'parse existing opf' do
    it 'should be initialized with opf' do
      opf = GEPUB::PackageData.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test.opf'), '/package.opf')
      opf.ns_prefix(GEPUB::XMLUtil::OPF_NS).should == 'xmlns'
      opf['version'].should == '3.0'
      opf['unique-identifier'].should == 'pub-id'
      opf['xml:lang'].should == 'ja'
    end
  end
  context 'generate new opf' do
    it 'should generate opf' do
      opf = GEPUB::PackageData.new('OEBPS/package.opf') {
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
        opf.ordered {
          opf.add_item('text/chapter1.xhtml')
          opf.add_item('text/chapter2.xhtml')
        }
      }
      puts opf.to_xml
      
    end
  end
end
