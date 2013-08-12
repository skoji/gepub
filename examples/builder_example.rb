# -*- coding: utf-8 -*-
    require 'rubygems'
    require 'gepub'
    workdir = 'epub/example/'
    builder = GEPUB::Builder.new {
      unique_identifier 'http:/example.jp/bookid_in_url', 'BookID', 'URL'
      language 'en'

      title 'GEPUB Sample Book'
      subtitle 'This book is just a sample'
      alt 'ja' => 'これはあくまでサンプルです'

      creator 'KOJIMA Satoshi'
      alt 'ja' => '小嶋智'

      contributors 'Denshobu', 'Asagaya Densho', 'Shonan Densho Teidan', 'eMagazine Torutaru'

      date '2012-02-29T00:00:00Z'

      resources(:workdir => workdir) {
        cover_image 'img/image1.jpg' => 'image1.jpg'
        ordered {
          file 'text/chap1.xhtml'
          heading 'Chapter 1'
          file 'text/chap1-1.xhtml'
          file 'text/chap2.html'
          heading 'Chapter 2'
        }
      }
    }
    epubname = File.join(File.dirname(__FILE__), 'example_test_with_builder.epub')
    builder.generate_epub(epubname)
