require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'

describe GEPUB::Book do
  context 'on creating new book' do
    describe 'initialize' do
      context 'without parameter' do
        it 'returns empty book' do
          book = GEPUB::Book.new()
          expect(book.path) .to eq('OEBPS/package.opf')
          expect(book.version).to eq('3.0')
        end
      end
      context 'with path' do
        it 'returns empty book with path' do
          book = GEPUB::Book.new('mypath/foo.opf')
          expect(book.path) .to eq('mypath/foo.opf')
        end
      end
      context 'with path and attributes' do
        it 'returns empty book with path and attributes' do
          book = GEPUB::Book.new('mypath/book.opf', {'version' => '2.1'});
          expect(book.path) .to eq('mypath/book.opf')
          expect(book.version).to eq('2.1')
        end
      end
    end 
    describe 'version=' do
      context 'overwrite version' do
        it 'will hold new version' do
          GEPUB::Book.new do |book|
            book.version = '2.1'
            expect(book.version).to eq('2.1')
          end
        end
      end
    end
    describe 'identifer=' do
      context 'set identifier' do
        it 'will set unique-identifier and related attributes' do
          GEPUB::Book.new do |book|
            book.identifier = 'the-book-identifier'
            expect(book.identifier).to eq('the-book-identifier')
            expect(book.identifier_list[0]['id']).to eq(book.unique_identifier)
            expect(book.identifier_list[0].refiner('identifier-type')).to be_nil
          end
        end
      end 
    end
    describe 'primary_identifier' do 
      context 'set identifier with id and type' do
        it 'will set unique-identifier and related attributes' do
          book = GEPUB::Book.new do
            primary_identifier 'http//example.com/the-identifier', 'MyBookID', 'URL'
          end
          expect(book.identifier).to eq('http//example.com/the-identifier')
          expect(book.unique_identifier).to eq('MyBookID')
          expect(book.identifier_list[0]['id']).to eq('MyBookID')
          expect(book.identifier_list[0].identifier_type.content).to eq('URL')
        end
      end 
    end
    describe 'add_identifier' do
      context 'add new identifier to new book' do
        it 'will set identifier, and not set unique-identifier' do
          book = GEPUB::Book.new()
          book.add_identifier 'newid'
          expect(book.unique_identifier).to be_nil
          expect(book.identifier).to be_nil
          expect(book.identifier_list[0].content).to eq('newid')
        end
      end
      context 'add new identifier to existing book' do
        it 'will set new identifier' do
          book = GEPUB::Book.new()
          book.identifier = 'theIdentifier'
          book.add_identifier 'http://example.jp/additional_identifier', nil, 'URL'
          expect(book.identifier).to eq('theIdentifier')
          expect(book.identifier_list[1].content).to eq('http://example.jp/additional_identifier')
          expect(book.identifier_list[1].identifier_type.content).to eq('URL')
        end
      end
    end
    describe 'add_title' do
      context 'add  title' do
        it 'adds new title' do
          book = GEPUB::Book.new()
          book.title = 'the title'
          book.add_title 'new title'
          expect(book.title.to_s).to eq('the title')
          expect(book.title_list[1].to_s).to eq('new title')
        end
      end 
    end
    describe 'title =' do 
      context 'set first title' do
        it 'will add new title' do
          book = GEPUB::Book.new()
          book.title = 'the title'
          expect(book.title.to_s).to eq('the title')
        end
      end 
      context 'clear and set title' do
        it 'will clear title and add new title' do
          book = GEPUB::Book.new()
          book.add_title 'the title'
          book.title = 'new title'
          expect(book.title.to_s).to eq('new title')
        end
      end 
    end
    describe 'title' do
      context 'main title is specified' do
        it 'returns main title' do
          book = GEPUB::Book.new()
          book.add_title 'sub title' 
          book.add_title('the main title', nil, GEPUB::TITLE_TYPE::MAIN) 
          expect(book.title.to_s).to eq('the main title')
        end
      end
      context 'display_seq is specified' do
        it 'returns first title' do
          book = GEPUB::Book.new()
          book.add_title 'second title' 
          book.add_title('first title') do
            |title|
            title.display_seq = 1
          end 
          expect(book.title.to_s).to eq('first title')
        end
      end
    end
    describe 'title_list' do 
      context 'main title is specified' do
        it 'returns titles in defined order' do
          book = GEPUB::Book.new()
          book.add_title 'sub title' 
          book.add_title('the main title', nil, GEPUB::TITLE_TYPE::MAIN) 
          expect(book.title_list[0].to_s).to eq('sub title')
          expect(book.title_list[1].to_s).to eq('the main title')
        end
        context 'display seq is specified' do
          it 'returns titles in display-seq order' do
            book = GEPUB::Book.new()
            book.add_title 'third title' 
            book.add_title 'fourth title' 
            book.add_title 'second title' do
              |title|
              title.display_seq = 2
            end 
            book.add_title('first title') do
              |title|
              title.display_seq = 1
            end 
            expect(book.title_list[0].to_s).to eq('first title')
            expect(book.title_list[1].to_s).to eq('second title')
            expect(book.title_list[2].to_s).to eq('third title')
            expect(book.title_list[3].to_s).to eq('fourth title')
          end
        end
      end
    end
    describe 'add_creator' do
      it 'adds new creator' do
        book = GEPUB::Book.new()
        book.creator = 'the creator'
        book.add_creator 'new creator'
        expect(book.creator.to_s).to eq('the creator')
        expect(book.creator_list[1].to_s).to eq('new creator')
      end
    end 
    describe 'creator=' do 
      it 'set first creator' do
        book = GEPUB::Book.new()
        book.creator = 'the creator'
        expect(book.creator.to_s).to eq('the creator')
      end
      it 'clear and set creator' do
        book = GEPUB::Book.new()
        book.creator = 'the creator'
        book.creator = 'new creator'
        expect(book.creator.to_s).to eq('new creator')
        expect(book.creator_list.size).to eq(1)
      end
    end
    describe 'creator' do
      context 'display seq is specified' do
        it 'shows creator with smallest display-seq' do
          book = GEPUB::Book.new()
          book.add_creator 'a creator'
          book.add_creator('second creator') do 
            |creator|
            creator.display_seq = 2
          end
          expect(book.creator.to_s).to eq('second creator')
        end
      end
    end

    describe 'creator_list' do
      context 'display seq is specified' do
        it 'returns creators in display-seq order' do
          book = GEPUB::Book.new()
          book.add_creator 'a creator'
          book.add_creator('second creator') do 
            |creator|
            creator.display_seq = 2
          end
          book.add_creator 'another creator'
          book.add_creator('first creator') do 
            |creator|
            creator.display_seq = 1
          end
          book.add_creator('third creator') do 
            |creator|
            creator.display_seq = 3
          end
          expect(book.creator_list[0].to_s).to eq('first creator')
          expect(book.creator_list[1].to_s).to eq('second creator')
          expect(book.creator_list[2].to_s).to eq('third creator')
          expect(book.creator_list[3].to_s).to eq('a creator')
          expect(book.creator_list[4].to_s).to eq('another creator')
        end
      end
    end

    # omit tests for setter/getter for contributor, publisher, date etc; these methods use same implementation as creator. 

    describe 'set_lastmodified' do
      it 'set current time' do
        book = GEPUB::Book.new
        now = Time.now
        book.modified_now
        expect((book.lastmodified.content - now).abs).to be < 2
      end
      it 'set time in string' do
        book = GEPUB::Book.new
        book.lastmodified(Time.parse('2012-9-12 00:00:00Z'))
        expect(book.lastmodified.content).to eq(Time.parse('2012-9-12 00:00:00 UTC'))
      end
      it 'set time in string : using assign method' do
        book = GEPUB::Book.new
        book.lastmodified = Time.parse('2012-9-12 00:00:00Z')
        expect(book.lastmodified.content).to eq(Time.parse('2012-9-12 00:00:00 UTC'))
      end
    end
    describe 'page_progression_direction=' do
      it 'set page_progression_direction' do 
        book = GEPUB::Book.new
        book.page_progression_direction= 'rtl'
        expect(book.page_progression_direction).to eq('rtl')
      end
    end
    describe 'add_optional_file' do
      context 'add apple specific option file' do
        it 'is added to book' do
          content = <<-EOF
                <?xml version="1.0" encoding="UTF-8"?>
                <display_options>
                <platform name="*">
                <option name="fixed-layout">true</option>
                </platform>
                </display_options>
                EOF
          book = GEPUB::Book.new
          book.add_optional_file('META-INF/com.apple.ibooks.display-options.xm', StringIO.new(content))

          expect(book.optional_files.size).to eq(1)
          expect(book.optional_files['META-INF/com.apple.ibooks.display-options.xm']).to eq(content)
        end
      end
    end
    describe 'add_item' do
    end
    describe 'add_ordered_item' do
    end
    describe 'ordered' do
    end
    describe 'write_to_epub_container' do
      context 'create typical book' do
      end
      context 'create very complex book' do
      end
    end
  end
  context 'on parsing existing book' do
    describe '.parse' do
     context 'IO Object' do
      it 'loads book and returns GEPUB::Book object' do
       filehandle = File.new(File.dirname(__FILE__) + '/fixtures/testdata/wasteland-20120118.epub')
       book = GEPUB::Book.parse(filehandle)
       expect(book).to be_instance_of GEPUB::Book
       expect(book.items.size).to eq 6
       expect(book.items['t1'].href).to eq 'wasteland-content.xhtml'
       expect(book.items['nav'].href).to eq 'wasteland-nav.xhtml'
       expect(book.items['cover'].href).to eq 'wasteland-cover.jpg'
       expect(book.items['css'].href).to eq 'wasteland.css'
       expect(book.items['css-night'].href).to eq 'wasteland-night.css'
       expect(book.items['ncx'].href).to eq 'wasteland.ncx'              
       expect(book.spine_items.size).to eq 1
       expect(book.spine_items[0].href).to eq 'wasteland-content.xhtml'
      end
     end
    end
  end
end
