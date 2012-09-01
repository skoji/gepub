# -*- coding: utf-8 -*-
p# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'

describe GEPUB::Metadata do
  it 'should be initialized' do
    metadata = GEPUB::Metadata.new
    metadata.ns_prefix(GEPUB::XMLUtil::DC_NS).should == 'dc'
    metadata.ns_prefix(GEPUB::XMLUtil::OPF_NS).should be_nil
  end
  it 'should be initialized with version 2.0' do
    metadata = GEPUB::Metadata.new('2.0')
    metadata.ns_prefix(GEPUB::XMLUtil::DC_NS).should == 'dc'
    metadata.ns_prefix(GEPUB::XMLUtil::OPF_NS).should == 'opf'
  end

  context 'Parse Existing OPF' do
    before do
      @metadata = GEPUB::Package.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test.opf'), '/package.opf').instance_eval{ @metadata }
    end
    it 'should parse title' do
      @metadata.main_title.should == 'TheTitle'
      @metadata.title_list.size.should == 2
      @metadata.title.to_s.should == 'TheTitle'
    end
    
    it 'should parse main title with not first display-seq' do
      metadata = GEPUB::Package.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test2.opf'), '/package.opf').instance_eval{ @metadata }
      metadata.title.to_s.should == 'TheTitle'
    end

    it 'should parse title-type' do
      @metadata.title_list[0].refiner_list('title-type').size.should == 1
      @metadata.title_list[0].refiner_list('title-type')[0].content.should == 'main'
      @metadata.title_list[1].refiner_list('title-type').size.should == 1
      @metadata.title_list[1].refiner_list('title-type')[0].content.should == 'collection'
    end

    it 'should parse identifier' do
      @metadata.identifier_list.size.should == 2
      @metadata.identifier.to_s.should == 'urn:uuid:1234567890'
      @metadata.identifier_list[0].content.should == 'urn:uuid:1234567890'
      @metadata.identifier_list[0].refiner('identifier-type').to_s.should == 'uuid'
      @metadata.identifier_list[1].content.should == 'http://example.jp/epub/test/url'
      @metadata.identifier_list[1].refiner('identifier-type').to_s.should == 'uri'
    end

    it 'should parse OPF2.0 meta node' do
      @metadata.oldstyle_meta.size.should == 1
      @metadata.oldstyle_meta[0].name == 'meta'
      @metadata.oldstyle_meta[0]['name'] == 'cover'
      @metadata.oldstyle_meta[0]['content'] == 'cover-image'
    end
  end

  context 'Should parse OPF2.0' do
    before do
      @metadata = GEPUB::Package.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/package_2_0.opf'), '/package.opf').instance_eval{ @metadata }
    end
    it 'should parse title' do
      @metadata.main_title.should == 'thetitle'
      @metadata.title_list.size.should == 1
    end
    it 'should parse OPF2.0 meta node' do
      @metadata.oldstyle_meta.size.should == 1
      @metadata.oldstyle_meta[0].name == 'meta'
      @metadata.oldstyle_meta[0]['name'] == 'cover'
      @metadata.oldstyle_meta[0]['content'] == 'cover-image'
    end
  end
  
  context 'Generate New OPF' do
    it 'should write and read identifier' do
      metadata = GEPUB::Metadata.new
      metadata.add_identifier 'the_set_identifier', 'pub-id'
      metadata.identifier.to_s.should == 'the_set_identifier'
      metadata.identifier_list[0]['id'].should == 'pub-id'
    end

    it 'should write and read identifier with identifier-type' do
      metadata = GEPUB::Metadata.new
      metadata.add_identifier 'http://example.jp/book/url', 'pub-id', 'uri'
      metadata.identifier.to_s.should == 'http://example.jp/book/url'
      metadata.identifier_list[0]['id'].should == 'pub-id'
      metadata.identifier_list[0].identifier_type.to_s.should == 'uri'
    end

    it 'should write and read title' do
      metadata = GEPUB::Metadata.new
      metadata.add_title('The Main Title')
      metadata.title.to_s.should == 'The Main Title'
    end

    it 'should write and read title with type' do
      metadata = GEPUB::Metadata.new
      metadata.add_title('The Main Title', 'maintitle', GEPUB::TITLE_TYPE::MAIN)
      metadata.title.to_s.should == 'The Main Title'
      metadata.title.title_type.to_s.should == 'main'
    end

    it 'should write and read multipletitle with type' do
      metadata = GEPUB::Metadata.new
      metadata.add_title('The Main Title', 'maintitle', GEPUB::TITLE_TYPE::MAIN)
      metadata.add_title('The Book Series', 'series', GEPUB::TITLE_TYPE::COLLECTION).set_group_position(1)
      metadata.title.to_s.should == 'The Main Title'
      metadata.title.title_type.to_s.should == 'main'

      metadata.title_list[1].to_s.should == 'The Book Series'
      metadata.title_list[1].title_type.to_s.should == 'collection'
      metadata.title_list[1].group_position.to_s.should == '1'
    end

    it 'should handle alternate-script metadata of creator, not using method chain' do
      metadata = GEPUB::Metadata.new
      metadata.add_creator('TheCreator', 'author', 'aut').set_display_seq(1).set_file_as('Creator, The').add_alternates({ 'ja-JP' => '作成者' })
      metadata.creator.to_s.should == 'TheCreator'
      metadata.creator.to_s('ja').should == '作成者'
    end
    
    it 'should handle alternate-script metadata of creator, not using method chain' do
      metadata = GEPUB::Metadata.new
      m = metadata.add_creator('TheCreator', 'author', 'aut')
      m.display_seq = 1
      m.file_as = 'Creator, The'
      m.add_alternates({ 'ja-JP' => '作成者' })

      metadata.creator.to_s.should == 'TheCreator'
      metadata.creator.to_s('ja').should == '作成者'
    end

    it 'should detect duplicate id' do
      metadata = GEPUB::Metadata.new
      metadata.add_creator('TheCreator', 'id', 'aut')
      lambda { metadata.add_title('TheTitle', 'id') }.should raise_error(RuntimeError, "id 'id' is already in use.")
    end

    it 'should generate empty metadata xml' do
      metadata = GEPUB::Metadata.new
      builder = Nokogiri::XML::Builder.new { |xml|
        xml.package('xmlns' => "http://www.idpf.org/2007/opf",'version' => "3.0",'unique-identifier' => "pub-id",'xml:lang' => "ja") {
          metadata.to_xml(xml)
        }
      }
      xml = Nokogiri::XML::Document.parse(builder.to_xml).at_xpath('//xmlns:metadata', { 'xmlns' => GEPUB::XMLUtil::OPF_NS})
      xml.namespaces['xmlns:dc'].should == GEPUB::XMLUtil::DC_NS
    end

    it 'should handle date with Time object' do
      metadata = GEPUB::Metadata.new
      a = Time.parse '2012-02-27 20:00:00 UTC'
      metadata.add_date(a, 'date')
      metadata.date.to_s.should ==  '2012-02-27T20:00:00Z'
    end

    it 'should handle date with a not W3C-DTF string' do
      metadata = GEPUB::Metadata.new
      metadata.add_date('2012-02-28 05:00:00 +0900', 'date')
      metadata.date.to_s.should ==  '2012-02-27T20:00:00Z'
    end
    
    it 'should generate metadata with id xml' do
      metadata = GEPUB::Metadata.new
      metadata.add_identifier('the_uid', nil)
      builder = Nokogiri::XML::Builder.new { |xml|
        xml.package('xmlns' => "http://www.idpf.org/2007/opf",'version' => "3.0",'unique-identifier' => "pub-id",'xml:lang' => "ja") {
          metadata.to_xml(xml)
        }
      }
      Nokogiri::XML::Document.parse(builder.to_xml).at_xpath('//dc:identifier', metadata.instance_eval {@namespaces}).content.should == 'the_uid'
    end

    it 'should generate metadata with creator refiner' do
      metadata = GEPUB::Metadata.new
      metadata.add_creator('TheCreator', nil, 'aut').set_display_seq(1).set_file_as('Creator, The').add_alternates({ 'ja-JP' => '作成者' })
      builder = Nokogiri::XML::Builder.new { |xml|
        xml.package('xmlns' => "http://www.idpf.org/2007/opf",'version' => "3.0",'unique-identifier' => "pub-id",'xml:lang' => "ja") {
          metadata.to_xml(xml)
        }
      }
      xml = Nokogiri::XML::Document.parse(builder.to_xml)
      ns = metadata.instance_eval { @namespaces }
      xml.at_xpath('//dc:creator', ns).content.should == 'TheCreator'
      id = xml.at_xpath('//dc:creator', ns)['id']
      xml.at_xpath("//xmlns:meta[@refines='##{id}' and @property='role']").content.should == 'aut'
      xml.at_xpath("//xmlns:meta[@refines='##{id}' and @property='display-seq']").content.should == '1'
      xml.at_xpath("//xmlns:meta[@refines='##{id}' and @property='file-as']").content.should == 'Creator, The'
      xml.at_xpath("//xmlns:meta[@refines='##{id}' and @property='alternate-script' and @xml:lang='ja-JP']").content.should == '作成者'
    end

    it 'should generate metadata with old style meta tag' do
      metadata = GEPUB::Metadata.new
      metadata.add_creator('TheCreator', nil, 'aut').set_display_seq(1).set_file_as('Creator, The').add_alternates({ 'ja-JP' => '作成者' })
      metadata.add_oldstyle_meta(nil, { 'name' => 'cover', 'content' => 'cover.jpg' })
      builder = Nokogiri::XML::Builder.new { |xml|
        xml.package('xmlns' => "http://www.idpf.org/2007/opf",'version' => "3.0",'unique-identifier' => "pub-id",'xml:lang' => "ja") {
          metadata.to_xml(xml)
        }
      }
      xml = Nokogiri::XML::Document.parse(builder.to_xml)
      xml.xpath("//xmlns:meta[@name='cover' and @content='cover.jpg']").size.should == 1
    end
  end
end
