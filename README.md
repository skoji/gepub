# gepub  

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/skoji/gepub?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[<img src="https://secure.travis-ci.org/skoji/gepub.png" />](http://travis-ci.org/skoji/gepub) 
[![Coverage Status](https://coveralls.io/repos/skoji/gepub/badge.png?branch=master)](https://coveralls.io/r/skoji/gepub?branch=master)
[![Dependency Status](https://gemnasium.com/skoji/gepub.png)](https://gemnasium.com/skoji/gepub)
[![Gem Version](https://badge.fury.io/rb/gepub.png)](http://badge.fury.io/rb/gepub)

* http://rdoc.info/github/skoji/gepub/master/frames

## DESCRIPTION:

a generic EPUB parser/generator library.

## FEATURES/PROBLEMS:

* GEPUB::Book provides functionality to create EPUB file, and parsing EPUB files
* Handle every metadata in EPUB2/EPUB3.
* GEPUB::Builder provides an easy and powerful way to create EPUB3 files

* See [issues](https://github.com/skoji/gepub/issues/) for known problems.

If you are using GEPUB::Builder from your code and do not like its behaviour(e.g. the block inside is evaluated as inside the Builder instance), please consider using GEPUB::Book directly.

**GEPUB::Builder will be obsolete in gepub 0.7. GEPUB::Book#new will be enhanced instead of Builder DSL.**


## SYNOPSIS:

### Builder Example

```ruby
require 'rubygem'
require 'gepub'
builder = GEPUB::Builder.new {
  language 'en'
  unique_identifier 'http:/example.jp/bookid_in_url', 'BookID', 'URL'
  title 'GEPUB Sample Book'
  subtitle 'This book is just a sample'

  creator 'KOJIMA Satoshi'

  contributors 'Denshobu', 'Asagaya Densho', 'Shonan Densho Teidan', 'eMagazine Torutaru'

  date '2012-02-29T00:00:00Z'

  resources(:workdir => '~/epub/sample_book_source/') {
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
```
[more builder examples](https://gist.github.com/1878995)
 [examples in this repository](https://github.com/skoji/gepub/tree/master/examples/) 

## INSTALL:

* gem install gepub



[![endorse](http://api.coderwall.com/skoji/endorse.png)](http://coderwall.com/skoji)
