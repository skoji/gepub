# -*- coding: utf-8 -*-
require 'gepub'

GEPUB::Book.new do |book|
  book.set_unique_identifier 'http:/example.jp/bookid_in_url', 'BookID', 'URL'
  book.set_title 'GEPUB Sample Book'
  book.set_subtitle 'GEPUB Sample Book'
  book.set_creator 'KOJIMA Satoshi'
  book.set_contributors '電書部', 'アサガヤデンショ', '電子雑誌トルタル'

  book.ordered {
    book.add_item('name') do
      |item|
      item.content = StringIO.new()
    end
  }
end



