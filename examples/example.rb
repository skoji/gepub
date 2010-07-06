# -*- coding: utf-8 -*-
require 'rubygems'
require 'gepub'
require 'fileutils'

epubname = "testepub.epub"
title = "samplepub"

epub = GEPUB::Book.new(title)
epub.author="the author"
epub.publisher="the publisher"
epub.date = "2010-05-03"
epub.identifier = "http://www.skoji.jp/testepub/2010-05-03"

# create test contents files

contents = {}
[ 'coverpage', 'chapter1', 'chapter2' ].each {
  |name|
  contents[name] = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" lang="ja" xml:lang="ja">
<head>
<title>sample #{name} </title>
</head>
<body>
<h1>#{name}</h1>
<p>here comes the contents for #{name}</p>
</body>
</html>
EOF
}

# coverpage won't appear on toc, so do not call addNav
epub.spine << epub.add_item('coverpage.html', StringIO.new(contents['coverpage']))
chap1 = epub.add_item("chapter1.html", StringIO.new(contents['chapter1']))
epub.spine << chap1
epub.add_nav(chap1, 'Chapter 1')
chap2 = epub.add_item("chapter2.html", StringIO.new(contents['chapter2']))
epub.spine << chap2
# if there are image files, they need not add to spine.
epub.add_nav(chap2, 'Chapter 2')

# GEPUB::Book#add_ordered_item will added on <manifest> and <spine> section.
# if you want to add image file, use GEPUB::Book#add_item instead.
epub.generate_epub(epubname)



