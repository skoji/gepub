# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rubygems'
describe GEPUB::Builder do
  context 'metadata generating' do
    it 'should generate language' do
      builder = GEPUB::Builder.new {
        language 'ja'
      }
      builder.instance_eval { @book.language }.to_s.should == 'ja'
    end

    it 'should generate uid' do
      builder = GEPUB::Builder.new {
        unique_identifier 'http://example.jp/as_url', 'BookID', 'url'
      }
      builder.instance_eval { @book.identifier }.to_s.should == 'http://example.jp/as_url'
      builder.instance_eval { @book.identifier_list[0]['id']}.should == 'BookID'
      builder.instance_eval { @book.identifier_list[0].identifier_type}.to_s.should == 'url'
    end
    
    it 'should generate title' do
      builder = GEPUB::Builder.new {
        title 'The Book Title'
      }
      builder.instance_eval { @book.title }.to_s.should == 'The Book Title'
      builder.instance_eval { @book.title.title_type }.to_s.should == 'main'
    end

    it 'should generate title with type ' do
      builder = GEPUB::Builder.new {
        subtitle 'the sub-title'
      }
      builder.instance_eval { @book.title }.to_s.should == 'the sub-title'
      builder.instance_eval { @book.title.title_type }.to_s.should == 'subtitle'
    end

    it 'should generate collection title ' do
      builder = GEPUB::Builder.new {
        collection 'the collection', 3
      }
      builder.instance_eval { @book.title }.to_s.should == 'the collection'
      builder.instance_eval { @book.title.title_type }.to_s.should == 'collection'
      builder.instance_eval { @book.title.group_position }.to_s.should == '3'
    end

    it 'should refine title: alternates ' do
      builder = GEPUB::Builder.new {
        collection 'the collection', 3
        alt 'ja' => 'シリーズ'
      }
      builder.instance_eval { @book.title }.to_s.should == 'the collection'
      builder.instance_eval { @book.title.title_type }.to_s.should == 'collection'
      builder.instance_eval { @book.title.list_alternates['ja'] }.to_s.should == 'シリーズ'
    end

    it 'should refine title: file_as ' do
      builder = GEPUB::Builder.new {
        title 'メインタイトル'
        file_as 'main title'
      }
      builder.instance_eval { @book.title }.to_s.should == 'メインタイトル'
      builder.instance_eval { @book.title.title_type }.to_s.should == 'main'
      builder.instance_eval { @book.title.file_as }.to_s.should == 'main title'
    end

    it 'should refine title: alt and file_as ' do
      builder = GEPUB::Builder.new {
        title 'メインタイトル'
        file_as 'main title'
        alt 'en' => 'The Main Title'
      }
      builder.instance_eval { @book.title }.to_s.should == 'メインタイトル'
      builder.instance_eval { @book.title.title_type }.to_s.should == 'main'
      builder.instance_eval { @book.title.file_as }.to_s.should == 'main title'
      builder.instance_eval { @book.title.list_alternates['en'] }.to_s.should == 'The Main Title'
    end

    it 'should generate creator ' do
      builder = GEPUB::Builder.new {
        creator 'The Main Author'
      }
      builder.instance_eval { @book.creator }.to_s.should == 'The Main Author'
    end

    it 'should generate creator with role' do
      builder = GEPUB::Builder.new {
        creator 'The Illustrator', 'ill'
      }
      builder.instance_eval { @book.creator }.to_s.should == 'The Illustrator'
      builder.instance_eval { @book.creator.role}.to_s.should == 'ill'
    end

    it 'should generate contributor ' do
      builder = GEPUB::Builder.new {
        contributor 'contributor', 'edt'
      }
      builder.instance_eval { @book.contributor }.to_s.should == 'contributor'
      builder.instance_eval { @book.contributor.role}.to_s.should == 'edt'
    end

    it 'should generate multiple creators ' do
      builder = GEPUB::Builder.new {
        creators 'First Author', 'Second Author', ['Third Person', 'edt']
      }
      builder.instance_eval { @book.creator_list }.size.should == 3
      builder.instance_eval { @book.creator_list[0] }.to_s.should == 'First Author'
      builder.instance_eval { @book.creator_list[1] }.to_s.should == 'Second Author'
      builder.instance_eval { @book.creator_list[2] }.to_s.should == 'Third Person'
      builder.instance_eval { @book.creator_list[2].role }.to_s.should == 'edt'
    end

    it 'should generate multiple creators, and then add file_as at once ' do
      builder = GEPUB::Builder.new {
        creators 'First Author', 'Second Author', ['Third Person', 'edt']
        file_as '1st', '2nd', '3rd'
      }
      builder.instance_eval { @book.creator_list }.size.should == 3
      builder.instance_eval { @book.creator_list[0] }.to_s.should == 'First Author'
      builder.instance_eval { @book.creator_list[0].file_as }.to_s.should == '1st'
      builder.instance_eval { @book.creator_list[1] }.to_s.should == 'Second Author'
      builder.instance_eval { @book.creator_list[1].file_as }.to_s.should == '2nd'
      builder.instance_eval { @book.creator_list[2] }.to_s.should == 'Third Person'
      builder.instance_eval { @book.creator_list[2].file_as }.to_s.should == '3rd'
      builder.instance_eval { @book.creator_list[2].role }.to_s.should == 'edt'
    end


    it 'should generate multiple creators, and multiple alternates ' do
      builder = GEPUB::Builder.new {
        creators 'First Author', 'Second Author', ['Third Person', 'edt']
        alts(
             'ja' => ['最初','二番目', '三番目'],
             'en' => ['first','second','third']
             )
      }
      builder.instance_eval { @book.creator_list }.size.should == 3
      builder.instance_eval { @book.creator_list[0] }.to_s.should == 'First Author'
      builder.instance_eval { @book.creator_list[0].list_alternates['ja'] }.to_s.should == '最初'
      builder.instance_eval { @book.creator_list[0].list_alternates['en'] }.to_s.should == 'first'
      builder.instance_eval { @book.creator_list[1] }.to_s.should == 'Second Author'
      builder.instance_eval { @book.creator_list[1].list_alternates['ja'] }.to_s.should == '二番目'
      builder.instance_eval { @book.creator_list[1].list_alternates['en'] }.to_s.should == 'second'
      builder.instance_eval { @book.creator_list[2] }.to_s.should == 'Third Person'
      builder.instance_eval { @book.creator_list[2].list_alternates['ja'] }.to_s.should == '三番目'
      builder.instance_eval { @book.creator_list[2].list_alternates['en'] }.to_s.should == 'third'
      builder.instance_eval { @book.creator_list[2].role }.to_s.should == 'edt'
    end
  end
  context 'resources' do
    it 'should add a file to book' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          file('text/memo.txt')
        }
      }
      builder.instance_eval{ @book.item_by_href('text/memo.txt') }.should_not be_nil
      builder.instance_eval{ @book.item_by_href('text/memo.txt').content.chomp }.should == 'just a plain text.'
    end

    it 'should add files to book' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          files('text/memo.txt','text/cover.xhtml')
        }
      }
      builder.instance_eval{ @book.item_by_href('text/memo.txt') }.should_not be_nil
      builder.instance_eval{ @book.item_by_href('text/memo.txt').content.chomp }.should == 'just a plain text.'
      builder.instance_eval{ @book.item_by_href('text/cover.xhtml') }.should_not be_nil
    end

    it 'should add files to book with glob' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          glob 'text/*.{txt,xhtml}'
        }
      }
      builder.instance_eval{ @book.item_by_href('text/memo.txt') }.should_not be_nil
      builder.instance_eval{ @book.item_by_href('text/memo.txt').content.chomp }.should == 'just a plain text.'
      builder.instance_eval{ @book.item_by_href('text/cover.xhtml') }.should_not be_nil
    end

    it 'should add files to book with import with prefix' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          import 'text/localresource.conf'
        }
      }
      builder.instance_eval{ @book.item_by_href('memo.txt') }.should_not be_nil
      builder.instance_eval{ @book.item_by_href('memo.txt').content.chomp }.should == 'just a plain text.'
      builder.instance_eval{ @book.item_by_href('cover.xhtml') }.should_not be_nil
    end

    it 'should add files to book with import with prefix' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          import 'text/localresource.conf', :dir_prefix => 'text'
        }
      }
      builder.instance_eval{ @book.item_by_href('text/memo.txt') }.should_not be_nil
      builder.instance_eval{ @book.item_by_href('text/memo.txt').content.chomp }.should == 'just a plain text.'
      builder.instance_eval{ @book.item_by_href('text/cover.xhtml') }.should_not be_nil
    end

    it 'should add files to book from IO object' do
      io = File.new(File.join(File.dirname(__FILE__),'fixtures', 'builder', 'text', 'memo.txt'))
      builder = GEPUB::Builder.new {
        resources()  {
          file('text/memo.txt' => io)
        }
      }
      builder.instance_eval{ @book.item_by_href('text/memo.txt') }.should_not be_nil
      builder.instance_eval{ @book.item_by_href('text/memo.txt').content.chomp }.should == 'just a plain text.'
    end

    it 'should add image file as cover' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          cover_image 'img/cover.jpg'
        }
      }
      builder.instance_eval{ @book.item_by_href('img/cover.jpg') }.should_not be_nil
      builder.instance_eval{ @book.item_by_href('img/cover.jpg').properties.member? 'cover-image' }.should ==  true
    end

    it 'should add file as nav' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          nav 'text/nav.xhtml'
        }
      }
      builder.instance_eval{ @book.item_by_href('text/nav.xhtml') }.should_not be_nil
      builder.instance_eval{ @book.item_by_href('text/nav.xhtml').properties.member? 'nav' }.should ==  true
    end

    it 'should specify mediatype' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          file('resources/noise.m4')
          media_type('audio/mp4')
        }
      }
      builder.instance_eval{ @book.item_by_href('resources/noise.m4') }.should_not be_nil        
      builder.instance_eval{ @book.item_by_href('resources/noise.m4').media_type }.should == 'audio/mp4'
    end

    it 'should specify mediatype to files' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          files('resources/noise.m4', 'resources/noise_2.m4a')
          media_type('audio/mp4')
        }
      }
      builder.instance_eval{ @book.item_by_href('resources/noise.m4') }.should_not be_nil        
      builder.instance_eval{ @book.item_by_href('resources/noise.m4').media_type }.should == 'audio/mp4'

      builder.instance_eval{ @book.item_by_href('resources/noise_2.m4a') }.should_not be_nil        
      builder.instance_eval{ @book.item_by_href('resources/noise_2.m4a').media_type }.should == 'audio/mp4'
    end

    it 'should specify mediatype to files using with_media_type' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          with_media_type('audio/mp4') {
            file('resources/noise.m4')
            file('resources/noise_2.m4a')
          }
          file('text/cover.xhtml')
        }
      }
      builder.instance_eval{ @book.item_by_href('resources/noise.m4') }.should_not be_nil        
      builder.instance_eval{ @book.item_by_href('resources/noise.m4').media_type }.should == 'audio/mp4'

      builder.instance_eval{ @book.item_by_href('resources/noise_2.m4a') }.should_not be_nil        
      builder.instance_eval{ @book.item_by_href('resources/noise_2.m4a').media_type }.should == 'audio/mp4'

      builder.instance_eval{ @book.item_by_href('text/cover.xhtml') }.should_not be_nil        
      builder.instance_eval{ @book.item_by_href('text/cover.xhtml').media_type }.should == 'application/xhtml+xml'
    end
    
    it 'should add files to book in spine' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          ordered {
            file('text/cover.xhtml')
            file('text/memo.txt')
          }
        }
      }
      builder.instance_eval{ @book.item_by_href('text/cover.xhtml') }.should_not be_nil
      builder.instance_eval{ @book.spine_items[0].href }.should ==  'text/cover.xhtml'
      builder.instance_eval{ @book.item_by_href('text/memo.txt') }.should_not be_nil
      builder.instance_eval{ @book.spine_items[1].href }.should ==  'text/memo.txt'
    end

    it 'should add files and heading' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          ordered {
            file('text/cover.xhtml')
            heading 'cover page'
            file('text/memo.txt')
            heading 'memo text'
          }
        }
      }
      builder.instance_eval{ @book.item_by_href('text/cover.xhtml') }.should_not be_nil
      builder.instance_eval{ @book.spine_items[0].href }.should ==  'text/cover.xhtml'
      builder.instance_eval{ @book.item_by_href('text/memo.txt') }.should_not be_nil
      builder.instance_eval{ @book.spine_items[1].href }.should ==  'text/memo.txt'
      builder.instance_eval{ @book.instance_eval { @toc[0][:item].href }}.should == 'text/cover.xhtml'
      builder.instance_eval{ @book.instance_eval { @toc[0][:text] }}.should == 'cover page'
      builder.instance_eval{ @book.instance_eval { @toc[1][:item].href }}.should == 'text/memo.txt'
      builder.instance_eval{ @book.instance_eval { @toc[1][:text] }}.should == 'memo text'
    end

    it 'should handle fallback chain' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          fallback_group {
            file 'chap3_docbook.xml' => nil
            media_type('application/docbook+xml')
            file 'chap3.xml' => nil
            media_type("application/z3986-auth+xml")
            file 'chap3.xhtml' => nil
          }
        }
      }
      builder.instance_eval {
        fallbackid = @book.item_by_href('chap3_docbook.xml').fallback
        @book.items[fallbackid].href.should == 'chap3.xml'

        fallbackid = @book.items[fallbackid].fallback
        @book.items[fallbackid].href.should == 'chap3.xhtml'        
      }
    end

    it 'should handle fallback chain with fallback_chain_files' do
      # in this test, do not supply 
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          fallback_chain_files({'chap3_docbook.xml' => nil}, {'chap3.xml' => nil}, {'chap3.xhtml' => nil})
        }
      }
      builder.instance_eval {
        fallbackid = @book.item_by_href('chap3_docbook.xml').fallback
        @book.items[fallbackid].href.should == 'chap3.xml'

        fallbackid = @book.items[fallbackid].fallback
        @book.items[fallbackid].href.should == 'chap3.xhtml'        
      }
    end

    it 'should handle fallback chain with fallback_chain_files in with_media_type' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        resources(:workdir => workdir)  {
          with_media_type('application/docbook+xml', 'application/z3986-auth+xml', 'application/xhtml+xml') {
            fallback_chain_files({'chap3_docbook.xml' => nil}, {'chap3.xml' => nil}, {'chap3.xhtml' => nil})
          }
        }
      }
      builder.instance_eval {
        @book.item_by_href('chap3_docbook.xml').media_type.should == 'application/docbook+xml'
        fallbackid = @book.item_by_href('chap3_docbook.xml').fallback
        @book.items[fallbackid].href.should == 'chap3.xml'
        @book.items[fallbackid].media_type.should == 'application/z3986-auth+xml'

        fallbackid = @book.items[fallbackid].fallback
        @book.items[fallbackid].href.should == 'chap3.xhtml'        
        @book.items[fallbackid].media_type.should == 'application/xhtml+xml'
      }
    end

    it 'should handle fallback chain in spine' do
      workdir = File.join(File.dirname(__FILE__),'fixtures', 'builder')
      builder = GEPUB::Builder.new {
        unique_identifier 'uid'

        resources(:workdir => workdir)  {
          ordered {
            fallback_group {
              file 'chap3_docbook.xml' => nil
              media_type('application/docbook+xml')
              file 'chap3.xml' => nil
              media_type("application/z3986-auth+xml")
              file 'chap3.xhtml' => nil
            }
          }
        }
      }
      builder.instance_eval {
        @book.cleanup
        fallbackid = @book.item_by_href('chap3_docbook.xml').fallback
        @book.items[fallbackid].href.should == 'chap3.xml'
        fallbackid = @book.items[fallbackid].fallback
        @book.items[fallbackid].href.should == 'chap3.xhtml'

        @book.spine_items.size.should == 1
        @book.spine_items[0].href == 'chap3_docbook.xhtml'

      }
    end

    it 'should create remote-resources' do
      builder = GEPUB::Builder.new {
        unique_identifier 'uid'
        resources {
          file 'with_remote.xhtml' => StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops"><head></head><body><div><p><video src="http://foo.bar">no video</video></p></div></body></html>')
        }
      }
      builder.instance_eval {
        @book.item_by_href('with_remote.xhtml').properties[0].should == 'remote-resources'
      }
    end

    it 'should handle remote resource URL' do
      builder = GEPUB::Builder.new {
        unique_identifier 'uid'
        resources {
          file 'http://foo.bar'
        }
      }
      # this should not raise 'No such file or directory'
    end

    it 'should handle mathml' do
      builder = GEPUB::Builder.new {
        unique_identifier 'uid'
        resources {
          file 'mathml.xhtml' => StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops"><head></head><body><div><p><math xmlns="http://www.w3.org/1998/Math/MathML"></math></p></div></body></html>')
        }
      }
      builder.instance_eval {
        @book.item_by_href('mathml.xhtml').properties[0].should == 'mathml'
      }
    end

    it 'should handle svg' do
      builder = GEPUB::Builder.new {
        unique_identifier 'uid'
        resources {
          file 'svg.xhtml' => StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops"><head></head><body><div><p><svg xmlns="http://www.w3.org/2000/svg"></svg></p></div></body></html>')
        }
      }
      builder.instance_eval {
        @book.item_by_href('svg.xhtml').properties[0].should == 'svg'
      }
    end

    it 'should handle epub:switch' do
      builder = GEPUB::Builder.new {
        unique_identifier 'uid'
        resources {
          file 'switch.xhtml' => StringIO.new('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops"><head></head><body><div><p>
<epub:switch>
   <epub:case required-namespace="http://www.xml-cml.org/schema">
      <cml xmlns="http://www.xml-cml.org/schema">
         <molecule id="sulfuric-acid">
            <formula id="f1" concise="H 2 S 1 O 4"/>
         </molecule>
      </cml>
   </epub:case>
   <epub:default>
      <p>H<sub>2</sub>SO<sub>4</sub></p>
   </epub:default>
</epub:switch></p></div></body></html>')
        }
      }
      builder.instance_eval {
        @book.item_by_href('switch.xhtml').properties[0].should == 'switch'
      }
    end

  end
end
