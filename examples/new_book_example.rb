# -*- coding: utf-8 -*-
require 'gepub'

gbook = GEPUB::Book.new do |book|
  book.identifier = 'http://example.jp/bookid_in_url'
  book.title = 'GEPUB Sample Book'
  book.creator = 'KOJIMA Satoshi'
  book.contributor = '電書部'
  book.add_contributor 'アサガヤデンショ'
  book.add_contributor '電子雑誌トルタル'
  book.language = 'ja'

  book.ordered do
    item = book.add_item('name.xhtml')
    item.add_content StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c1</title></head><body><p>the first page</p></body></html>')end
end

gbook.generate_epub("test.epub")
