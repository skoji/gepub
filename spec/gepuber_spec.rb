# -*- coding: utf-8 -*-
# need to install 'epubcheck'.

require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'

describe GEPUB::Gepuber do
  it "should be initialized with empty conf" do
    gepuber = GEPUB::Gepuber.new({})
    gepuber.texts.should == ['[0-9]*.x?html']
    gepuber.resources.should == ['*.css',  'img/*']
    gepuber.title.should == ""
    gepuber.table_of_contents.should == {}
  end

  it "should read config hash" do
    conf = 
      {
      :locale => 'ja',
      :title => 'theTitle',
      :author => 'theAuthor',
      :publisher => 'thePublisher',
      :date => '2011-03-11',
      :identifier => 'http://skoji.jp/gepuber/2011-03-11.0.0',
      :epubname => 'gepub_00',
      :table_of_contents => {
        '1_.html' => '1st toc',
        '3_.html' => '3rd toc',
        '3_.html#a1' => '3rd toc 2',
        '9_.html' => 'last toc'
      },
      :coverimg => 'cover.gif',
      :texts => [ '*.html' ],
      :resources => ['*.css','*.gif']
    }

    gepuber = GEPUB::Gepuber.new(conf )
    gepuber.title.should == "theTitle"
    gepuber.locale.should == "ja"
    gepuber.author.should == "theAuthor"
    gepuber.publisher.should == "thePublisher"
    gepuber.date.should == "2011-03-11"
    gepuber.identifier.should == 'http://skoji.jp/gepuber/2011-03-11.0.0'
    gepuber.epubname.should == 'gepub_00'
    gepuber.coverimg.should == 'cover.gif'
    gepuber.table_of_contents.should == {  '1_.html' => '1st toc',  '3_.html' => '3rd toc', '3_.html#a1' => '3rd toc 2','9_.html' => 'last toc'}
    gepuber.texts.should == ['*.html']
    gepuber.resources.should == ['*.css',  '*.gif']

  end
end
