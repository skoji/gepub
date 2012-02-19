# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'

describe GEPUB::Gepuber do
  it "should be initialized with empty conf" do
    gepuber = GEPUB::Gepuber.new({})
    gepuber.texts.should == ['[0-9]*.{xhtml,html}']
    gepuber.resources.should == ['*.css',  'img/*']
    gepuber.title.to_s.should == ""
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
    gepuber.title.to_s.should == "theTitle"
    gepuber.locale.to_s.should == "ja"
    gepuber.author.to_s.should == "theAuthor"
    gepuber.publisher.to_s.should == "thePublisher"
    gepuber.date.to_s.should == "2011-03-11"
    gepuber.identifier.should == 'http://skoji.jp/gepuber/2011-03-11.0.0'
    gepuber.epubname.should == 'gepub_00'
    gepuber.coverimg.should == 'cover.gif'
    gepuber.table_of_contents.should == {  '1_.html' => '1st toc',  '3_.html' => '3rd toc', '3_.html#a1' => '3rd toc 2','9_.html' => 'last toc'}
    gepuber.texts.should == ['*.html']
    gepuber.resources.should == ['*.css',  '*.gif']

  end
end
