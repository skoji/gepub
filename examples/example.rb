# -*- coding: utf-8 -*-
require 'rubygems'
require 'gepub'
require 'fileutils'

epubdir = "testepub"
title = "samplepub"
FileUtils.rm_rf(epubdir)
FileUtils.mkdir(epubdir)

epub = GEPUB::Generator.new(title)
epub.author="the author"
epub.publisher="the publisher"
epub.date = "2010-05-03"
epub.identifier = "http://www.skoji.jp/testepub/2010-05-03"

# create test contents files

[ 'coverpage', 'chapter1', 'chapter2' ].each {
  |name|
  File.open(epubdir + "/#{name}.html", 'w') {
    |file|
    file << <<EOF
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
}

# coverpage won't appear on toc, so do not call addNav
epub.addManifest('cover', "coverpage.html", 'application/xhtml+xml')
epub.spine.push('cover')


epub.addManifest('chap1', "chapter1.html", 'application/xhtml+xml')
epub.spine.push('chap1')
epub.addNav('chap1', 'Chapter 1', "chapter1.html")

epub.addManifest('chap2', "chapter2.html", 'application/xhtml+xml')
epub.spine.push('chap2')
epub.addNav('chap1', 'Chapter 2', "chapter2.html")


epub.create(epubdir)
epub.create_epub(epubdir, ".")


