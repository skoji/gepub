require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'
describe GEPUB::Book do 
    context 'on creating new book' do
        describe 'initialize' do
            context 'with no parameter' do
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
                    book = GEPUB::Book.new()
                    book.version = '2.1'
                    expect(book.version).to eq('2.1')
                end
            end
        end
        describe 'identifer=' do
            context 'set identifier' do
                it 'will set unique-identifier and related attributes' do
                    book = GEPUB::Book.new()
                    book.identifier = 'the-book-identifier'

                    expect(book.identifier).to eq('the-book-identifier')
                    expect(book.identifier_list[0]['id']).to eq(book.unique_identifier)
                    expect(book.identifier_list[0].refiner('identifier-type')).to be_nil
                end
            end 
        end
        describe 'set_primary_identifier=' do 
            context 'set identifier with id and type' do
                it 'will set unique-identifier and related attributes' do
                    book = GEPUB::Book.new()
                    book.set_primary_identifier 'http//example.com/the-identifier', 'MyBookID', 'URL'

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
     end
     describe 'creator' do
     end
     describe 'creator_list' do
     end
     describe 'add_contributor' do
     end
     describe 'contributor' do
     end
     describe 'contributor_list' do
     end
     describe 'set_lastmodified' do
     end
     describe 'lastmodified' do
     end
     describe 'set_othermetadata' do
     end
     describe 'page_progression_direction=' do
     end
     describe 'add_optional_file' do
     end
     describe 'add_item' do
     end
     describe 'add_ordered_item' do
     end
     describe 'ordered' do
     end
     describe 'write_to_epub_container' do
     end
 end
 context 'on parsing existing book' do
 end
end