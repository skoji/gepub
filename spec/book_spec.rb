require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
require 'nokogiri'
describe GEPUB::Book do 
    context 'on creating new book' do
        describe 'initialize' do
            context 'with no parameter' do
                it 'returns empty book' do
                    book = GEPUB::Book.new();
                    book.instance_eval {
                        expect(@package.path).to eq('OEBPS/package.opf');
                    }
                end
            end
        end 
        describe 'version=' do
        end
        describe 'identifer=' do # TODO: this interface may be not necessary 
        end
        describe 'set_main_id=' do # TODO: rename
        end
        describe 'add_identifier' do
        end
        describe 'add_title' do 
        end
        describe 'set_title' do 
        end
        describe 'title_list' do #TODO: rename
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