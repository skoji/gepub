require 'rubygems'

module GEPUB
  class Gepuber < GEPUB::Book
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
    
    def initialize(param)
      super('', 'OEBPS')
      param.each {
        |k,v|
        self.send "#{k}=", v
      }
      @texts ||= ['[0-9]*.x?html'] 
      @resources ||= ['*.css',  'img/*']
      @coverimg ||= 'cover.jpg'
      @table_of_contents ||= {}
      @epubname ||= 'gepuber_generated'
      @provider ||= FileProvider
    end

    def create(destbasedir = ".")
      @provider.new(@texts).each {
        |f, fio|
        item = add_item(f, fio)
        @spine << item
        if !@table_of_contents[f].nil?
          add_nav(item, @table_of_contents[f]) 
          @table_of_contents.each {
            |k,v|
            k =~ /^#{f}#(.*)$/
            add_nav(item, v, $1) unless $1.nil?
          }
        end
      }

      @provider.new(@resources).each {
        |f, fio|
        item = add_item(f, fio)
        specify_cover_image(item) if File.basename(f) == @coverimg
      }
      generate_epub(File.join(destbasedir, @epubname + '.epub'))      
    end
  end
end
