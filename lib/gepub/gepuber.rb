require 'rubygems'

module GEPUB
  class Gepuber
    
    def self.book_setter(namelist)
      namelist.each {
        |name|
        define_method name.to_s + '=', do
          |arg|
          instance_variable_get('@book').send(name.to_s + '=' , arg)
        end
      }
    end

    attr_accessor :toc, :texts, :resources, :epubname, :coverimg, :book
    book_setter :title, :author, :publisher, :date, :identifier, :locale

    def initialize(str)
      @book = GEPUB::Book.new('', 'OEBPS')
      @book.locale = 'ja'
      instance_eval(str)
      @texts || = Dir.glob('[0-9]*.html')
      @resources ||= Dir.glob('*.css') + Dir.glob(File.join('img', '*'))
      @coverimg ||= 'cover.jpg'
      @toc ||= {}
      @epubname ||= 'gepuber_generated'
    end

    def create

      @texts.each {
        |f|
        File.open(f,'rb') {
          |fio|
          item = book.add_item(f, fio)
          @book.spine << item
          @book.add_nav(item, @toc[f]) if !@toc[f].nil?
        }
      }

      @resources.each {
        |f|
        File.open(f,'rb') {
          |fio|
          item = @book.add_item(f, fio)
          @book.specify_cover_image(item) if File.basename(f) == @coverimg
        }
      }
      book.generate_epub(File.join(destbasedir, @epubname + '.epub'))      
    end
  end
end
