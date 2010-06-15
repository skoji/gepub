# -*- coding: utf-8 -*-
require 'rubygems'
require 'xml/libxml'
require 'zip/zip'
require 'fileutils'


module GEPUB
  class Generator

    attr_accessor :spine

    def initialize(title)
      @metadata = Hash.new
      @manifest = Hash.new
      @spine = Array.new
      @toc = Array.new
      @metadata[:title] = title
      @manifest['ncx'] = { :href => 'toc.ncx', :mediatype => 'application/x-dtbncx+xml' }
      @contents_prefix = "" # may insert "OEBPS/"
    end

    def contents_prefix=(prefix)
      @contents_prefix =  prefix + "/"
    end

    def title
      @metadata[:title]
    end

    def title=(title)
      @metadata[:title] = title
    end

    def author
      @metadata[:creator]
    end

    def author=(author)
      @metadata[:creator] = author
    end

    def contributor
      @metadata[:contributor]
    end
    
    def contributor=(contributor)
      @metadata[:contributor] = contributor
    end

    def publisher
      @metadata[:publisher]
    end

    def publisher=(publisher)
      @metadata[:publisher] = publisher
    end
    
    def date
      @metadata[:date]
    end

    def date=(date)
      @metadata[:date] = date
    end
    
    def identifier
      @metadata[:itentifier]
    end

    def identifier=(id)
      @metadata[:identifier] = id
    end

    def addManifest(id, href, mediatype)
      @manifest[id] = { :href => href, :mediatype => mediatype }
    end
    
    def addNav(id, text, ref)
      @toc.push({ :id => id, :text => text, :ref => ref})
    end

    def specifyCoverImage(id)
      @metadata[:cover] = id
    end

    def create(destdir)
      create_mimetype(destdir)
      create_container(destdir)
      create_toc(destdir)
      create_opf(destdir)
    end
    
    def create_epub(destdir, targetdir, epubname = @metadata[:title])
      realtarget = File::expand_path(targetdir)
      FileUtils.cd("#{destdir}") do
        |dir|
        epubname = "#{realtarget}/#{epubname}.epub"
        File.delete(epubname) if File.exist?(epubname)
        
        Zip::ZipOutputStream::open(epubname) {
          |epub|
          epub.put_next_entry('mimetype', '', '', Zip::ZipEntry::STORED)
          epub << "application/epub+zip"

          Dir["**/*"].each do
            |f|
            if File.basename(f) != 'mimetype' && !File.directory?(f)
              File.open(f,'rb') do
                |file|
                epub.put_next_entry(f)
                epub << file.read
              end
            end
          end
        }
      end
    end

    def mimetype_contents
      <<EOF
application/epub+zip
EOF
    end
    def create_mimetype(destdir)
      File.open(destdir + '/mimetype', 'w') {
        | file |
        file << mimetype_contents
      }
    end

    def container_xml
      <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="#{@contents_prefix}content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
EOF
    end

    def create_container(destdir)
      infdir = destdir + "/META-INF"
      Dir.mkdir(infdir) if !File.exist?(infdir)

      File.open(infdir + "/container.xml", 'w') {
        |file|
        file << container_xml
      }
    end

    def opf_xml
      result = XML::Document.new
      result.root = XML::Node.new('package')
      package = result.root
      XML::Namespace.new(package, nil, 'http://www.idpf.org/2007/opf')
      package['version'] = '2.0'
      package['unique-identifier'] = 'BookID'


      package << metadataelem = XML::Node.new('metadata')
      XML::Namespace.new(metadataelem, 'opf', 'http://www.idpf.org/2007/opf')
      XML::Namespace.new(metadataelem, 'dc', "http://purl.org/dc/elements/1.1/")

      metadataelem << XML::Node.new('dc:language', 'ja')

      @metadata.each { | k, v |
        if (k == :cover)
          metadataelem << node = XML::Node.new("meta")
          node['name'] = 'cover'
          node['content'] = v
        else
          metadataelem << node = XML::Node.new("dc:#{k}",v)
          if (k == :identifier)
            node['id'] = 'BookID'
            node['opf:scheme'] = 'URL'
          end
        end
      }

      package << manifestelem = XML::Node.new('manifest')
      @manifest.each {|k,v|
        manifestelem << node = XML::Node.new("item")
        node['id'] = "#{k}"
        node['href'] = "#{v[:href]}"
        node['media-type'] = "#{v[:mediatype]}" 
      }
      
      package << spineelem = XML::Node.new('spine')
      spineelem['toc'] = 'ncx'

      @spine.each {
        |v|
        spineelem << node = XML::Node.new('itemref')
        node['idref'] = "#{v}"
      }

      result.to_s

    end

    def create_opf(destdir)
      File.open(destdir + "/" + @contents_prefix + "content.opf", 'w') { | file | file << opf_xml }
    end

    def ncx_xml
      result = XML::Document.new
      result.root = XML::Node.new('ncx')
      root = result.root
      XML::Namespace.new(root, nil, "http://www.daisy.org/z3986/2005/ncx/")
      root['version'] = "2005-1"
      root << head = XML::Node.new('head')
      head << uid = XML::Node.new('meta')
      uid['name'] = 'dtb:uid'
      uid['content'] = "#{@metadata[:identifier]}"

      head << depth = XML::Node.new('meta')
      depth['name'] = 'dtb:depth'
      depth['content'] = '1'

      head << totalPageCount = XML::Node.new('meta')
      totalPageCount['name'] = 'dtb:totalPageCount'
      totalPageCount['content'] = '0'

      head << maxPageNumber = XML::Node.new('meta')
      maxPageNumber['name'] = 'dtb:maxPageNumber'
      maxPageNumber['content'] = '0'


      root << docTitle = XML::Node.new('docTitle')
      docTitle << XML::Node.new('text', "#{@metadata[:title]}")
      
      root << nav_map = XML::Node.new('navMap')
      count = 1
      @toc.each {
        |x|
        nav_point = XML::Node.new('navPoint')
        nav_point['id'] = "#{x[:id]}"
        nav_point['playOrder'] = "#{count}"
        
        nav_label = XML::Node.new('navLabel')
        nav_label << XML::Node.new('text', "#{x[:text]}")
        
        nav_content = XML::Node.new('content')
        nav_content['src'] = "#{x[:ref]}"
        count = count + 1

        nav_map << nav_point
        nav_point << nav_label
        nav_point << nav_content
      }
      result.to_s
    end
    
    def create_toc(destdir)
      File.open(destdir + "/" + @contents_prefix + "toc.ncx", 'w') {
        |file|
        file << ncx_xml
      }
    end

  end
end
