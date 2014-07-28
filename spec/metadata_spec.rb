# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'

describe GEPUB::Metadata do
  it 'should be initialized' do
    metadata = GEPUB::Metadata.new
    expect(metadata.ns_prefix(GEPUB::XMLUtil::DC_NS)).to eq('dc')
    expect(metadata.ns_prefix(GEPUB::XMLUtil::OPF_NS)).to be_nil
  end
  it 'should be initialized with version 2.0' do
    metadata = GEPUB::Metadata.new('2.0')
    expect(metadata.ns_prefix(GEPUB::XMLUtil::DC_NS)).to eq('dc')
    expect(metadata.ns_prefix(GEPUB::XMLUtil::OPF_NS)).to eq('opf')
  end

  context 'Parse Existing OPF' do
    before do
      @metadata = GEPUB::Package.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test.opf'), '/package.opf').instance_eval{ @metadata }
    end
    it 'should parse title' do
      expect(@metadata.main_title).to eq('TheTitle')
      expect(@metadata.title_list.size).to eq(2)
      expect(@metadata.title.to_s).to eq('TheTitle')
    end
    
    it 'should parse main title with not first display-seq' do
      metadata = GEPUB::Package.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/test2.opf'), '/package.opf').instance_eval{ @metadata }
      expect(metadata.title.to_s).to eq('TheTitle')
    end

    it 'should parse title-type' do
      expect(@metadata.title_list[0].refiner_list('title-type').size).to eq(1)
      expect(@metadata.title_list[0].refiner_list('title-type')[0].content).to eq('main')
      expect(@metadata.title_list[1].refiner_list('title-type').size).to eq(1)
      expect(@metadata.title_list[1].refiner_list('title-type')[0].content).to eq('collection')
    end

    it 'should parse identifier' do
      expect(@metadata.identifier_list.size).to eq(2)
      expect(@metadata.identifier.to_s).to eq('urn:uuid:1234567890')
      expect(@metadata.identifier_list[0].content).to eq('urn:uuid:1234567890')
      expect(@metadata.identifier_list[0].refiner('identifier-type').to_s).to eq('uuid')
      expect(@metadata.identifier_list[1].content).to eq('http://example.jp/epub/test/url')
      expect(@metadata.identifier_list[1].refiner('identifier-type').to_s).to eq('uri')
    end

    it 'should parse OPF2.0 meta node' do
      expect(@metadata.oldstyle_meta.size).to eq(1)
      expect(@metadata.oldstyle_meta[0].name).to eq 'meta'
      expect(@metadata.oldstyle_meta[0]['name']).to eq 'cover'
      expect(@metadata.oldstyle_meta[0]['content']).to eq 'cover-image'
    end
  end

  context 'Should parse OPF2.0' do
    before do
      @metadata = GEPUB::Package.parse_opf(File.open(File.dirname(__FILE__) + '/fixtures/testdata/package_2_0.opf'), '/package.opf').instance_eval{ @metadata }
    end
    it 'should parse title' do
      expect(@metadata.main_title).to eq('thetitle')
      expect(@metadata.title_list.size).to eq(1)
    end
    it 'should parse OPF2.0 meta node' do
      expect(@metadata.oldstyle_meta.size).to eq(1)
      expect(@metadata.oldstyle_meta[0].name).to eq 'meta'
      expect(@metadata.oldstyle_meta[0]['name']).to eq 'cover'
      expect(@metadata.oldstyle_meta[0]['content']).to eq 'cover-image'
    end
  end
  
  context 'Generate New OPF' do
    it 'should write and read identifier' do
      metadata = GEPUB::Metadata.new
      metadata.add_identifier 'the_set_identifier', 'pub-id'
      expect(metadata.identifier.to_s).to eq('the_set_identifier')
      expect(metadata.identifier_list[0]['id']).to eq('pub-id')
    end

    it 'should write and read identifier with identifier-type' do
      metadata = GEPUB::Metadata.new
      metadata.add_identifier 'http://example.jp/book/url', 'pub-id', 'uri'
      expect(metadata.identifier.to_s).to eq('http://example.jp/book/url')
      expect(metadata.identifier_list[0]['id']).to eq('pub-id')
      expect(metadata.identifier_list[0].identifier_type.to_s).to eq('uri')
    end

    it 'should write and read title' do
      metadata = GEPUB::Metadata.new
      metadata.add_title('The Main Title')
      expect(metadata.title.to_s).to eq('The Main Title')
    end

    it 'should write and read title with type' do
      metadata = GEPUB::Metadata.new
      metadata.add_title('The Main Title', 'maintitle', GEPUB::TITLE_TYPE::MAIN)
      expect(metadata.title.to_s).to eq('The Main Title')
      expect(metadata.title.title_type.to_s).to eq('main')
    end

    it 'should write and read multipletitle with type' do
      metadata = GEPUB::Metadata.new
      metadata.add_title('The Main Title', 'maintitle', GEPUB::TITLE_TYPE::MAIN)
      metadata.add_title('The Book Series', 'series', GEPUB::TITLE_TYPE::COLLECTION).group_position(1)
      expect(metadata.title.to_s).to eq('The Main Title')
      expect(metadata.title.title_type.to_s).to eq('main')

      expect(metadata.title_list[1].to_s).to eq('The Book Series')
      expect(metadata.title_list[1].title_type.to_s).to eq('collection')
      expect(metadata.title_list[1].group_position.to_s).to eq('1')
    end

    it 'should handle alternate-script metadata of creator, not using method chain' do
      metadata = GEPUB::Metadata.new
      metadata.add_creator('TheCreator', 'author', 'aut').display_seq(1).file_as('Creator, The').add_alternates({ 'ja-JP' => '作成者' })
      expect(metadata.creator.to_s).to eq('TheCreator')
      expect(metadata.creator.to_s('ja')).to eq('作成者')
    end
    
    it 'should handle alternate-script metadata of creator, not using method chain' do
      metadata = GEPUB::Metadata.new
      m = metadata.add_creator('TheCreator', 'author', 'aut')
      m.display_seq = 1
      m.file_as = 'Creator, The'
      m.add_alternates({ 'ja-JP' => '作成者' })

      expect(metadata.creator.to_s).to eq('TheCreator')
      expect(metadata.creator.to_s('ja')).to eq('作成者')
    end

    it 'should detect duplicate id' do
      metadata = GEPUB::Metadata.new
      metadata.add_creator('TheCreator', 'id', 'aut')
      expect { metadata.add_title('TheTitle', 'id') }.to raise_error(RuntimeError, "id 'id' is already in use.")
    end

    it 'should generate empty metadata xml' do
      metadata = GEPUB::Metadata.new
      builder = Nokogiri::XML::Builder.new { |xml|
        xml.package('xmlns' => "http://www.idpf.org/2007/opf",'version' => "3.0",'unique-identifier' => "pub-id",'xml:lang' => "ja") {
          metadata.to_xml(xml)
        }
      }
      xml = Nokogiri::XML::Document.parse(builder.to_xml).at_xpath('//xmlns:metadata', { 'xmlns' => GEPUB::XMLUtil::OPF_NS})
      expect(xml.namespaces['xmlns:dc']).to eq(GEPUB::XMLUtil::DC_NS)
    end

    it 'should handle date with Time object' do
      metadata = GEPUB::Metadata.new
      a = Time.parse '2012-02-27 20:00:00 UTC'
      metadata.add_date(a, 'date')
      expect(metadata.date.to_s).to eq('2012-02-27T20:00:00Z')
    end

    it 'should handle date with Time object by content = ' do
      metadata = GEPUB::Metadata.new
      a = Time.parse '2012-02-27 20:00:00 UTC'
      metadata.add_date('2011-01-01', 'date')
      metadata.date.content = a
      expect(metadata.date.to_s).to eq('2012-02-27T20:00:00Z')
    end

    it 'should handle date with a not W3C-DTF string' do
      metadata = GEPUB::Metadata.new
      metadata.add_date('2012-02-28 05:00:00 +0900', 'date')
      expect(metadata.date.to_s).to eq('2012-02-27T20:00:00Z')
    end
    
    it 'should generate metadata with id xml' do
      metadata = GEPUB::Metadata.new
      metadata.add_identifier('the_uid', nil)
      builder = Nokogiri::XML::Builder.new { |xml|
        xml.package('xmlns' => "http://www.idpf.org/2007/opf",'version' => "3.0",'unique-identifier' => "pub-id",'xml:lang' => "ja") {
          metadata.to_xml(xml)
        }
      }
      expect(Nokogiri::XML::Document.parse(builder.to_xml).at_xpath('//dc:identifier', metadata.instance_eval {@namespaces}).content).to eq('the_uid')
    end

    it 'should generate metadata with creator refiner' do
      metadata = GEPUB::Metadata.new
      metadata.add_creator('TheCreator', nil, 'aut').display_seq(1).file_as('Creator, The').add_alternates({ 'ja-JP' => '作成者' })
      builder = Nokogiri::XML::Builder.new { |xml|
        xml.package('xmlns' => "http://www.idpf.org/2007/opf",'version' => "3.0",'unique-identifier' => "pub-id",'xml:lang' => "ja") {
          metadata.to_xml(xml)
        }
      }
      xml = Nokogiri::XML::Document.parse(builder.to_xml)
      ns = metadata.instance_eval { @namespaces }
      expect(xml.at_xpath('//dc:creator', ns).content).to eq('TheCreator')
      id = xml.at_xpath('//dc:creator', ns)['id']
      expect(xml.at_xpath("//xmlns:meta[@refines='##{id}' and @property='role']").content).to eq('aut')
      expect(xml.at_xpath("//xmlns:meta[@refines='##{id}' and @property='display-seq']").content).to eq('1')
      expect(xml.at_xpath("//xmlns:meta[@refines='##{id}' and @property='file-as']").content).to eq('Creator, The')
      expect(xml.at_xpath("//xmlns:meta[@refines='##{id}' and @property='alternate-script' and @xml:lang='ja-JP']").content).to eq('作成者')
    end

    it 'should generate metadata with old style meta tag' do
      metadata = GEPUB::Metadata.new
      metadata.add_creator('TheCreator', nil, 'aut').display_seq(1).file_as('Creator, The').add_alternates({ 'ja-JP' => '作成者' })
      metadata.add_oldstyle_meta(nil, { 'name' => 'cover', 'content' => 'cover.jpg' })
      builder = Nokogiri::XML::Builder.new { |xml|
        xml.package('xmlns' => "http://www.idpf.org/2007/opf",'version' => "3.0",'unique-identifier' => "pub-id",'xml:lang' => "ja") {
          metadata.to_xml(xml)
        }
      }
      xml = Nokogiri::XML::Document.parse(builder.to_xml)
      expect(xml.xpath("//xmlns:meta[@name='cover' and @content='cover.jpg']").size).to eq(1)
    end
  end
end
