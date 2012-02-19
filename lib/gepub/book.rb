# -*- coding: utf-8 -*-
require 'rubygems'
require 'nokogiri'
require 'zip/zip'
require 'fileutils'


module GEPUB
  class Book < Package
    def initialize(title, contents_prefix="")
      warn 'GEPUB::Book#new is deprecated. use GEPUB::Book#generate'
      super(contents_prefix)
      self.title = title if !title.nil? && title.size > 0
    end
  end
end
