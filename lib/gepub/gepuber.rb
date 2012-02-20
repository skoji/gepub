require 'rubygems'

module GEPUB
  class Gepuber
    class FileProvider
      include Enumerable
      def initialize(pattern)
        @list = Dir.glob(pattern)
      end

      def each (&block)
        @list.each {
          |f|
          File.open(f, 'rb') {
            |fio|
            yield f, fio
          }
        }
      end
    end

    attr_accessor :texts, :resources, :epubname, :coverimg, :table_of_contents, :provider
    
    def method_missing(name, *args)
      @book.send(name, *args)
    end
    
    def initialize(param)
      @book = GEPUB::Book.new()
      param.each {
        |k,v|
        self.send "#{k}=", v
      }
      @texts ||= ['[0-9]*.{xhtml,html}'] 
      @resources ||= ['*.css',  'img/*']
      @coverimg ||= 'cover.jpg'
      @table_of_contents ||= {}
      @epubname ||= 'gepuber_generated'
      @provider ||= FileProvider
    end

    def create(destbasedir = ".")
      @provider.new(@texts).each {
        |f, fio|
        @book.ordered {
          item = add_item(f, fio)
          if !@table_of_contents[f].nil?
            item.toc_text table_of_contents[f] 
            @table_of_contents.each {
              |k,v|
              k =~ /^#{f}#(.*)$/
              add_nav(item, v, $1) unless $1.nil?
            }
          end
        }
      }

      @provider.new(@resources).each {
        |f, fio|
        item = add_item(f, fio)
        item.cover_image if File.basename(f) == @coverimg
      }
      generate_epub(File.join(destbasedir, @epubname + '.epub'))      
    end
  end
end
