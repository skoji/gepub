require 'rubygems'

module GEPUB
  class Gepuber
    def initialize(&block)
      @block = block
    end

    def create
      table_of_contents = {}
      epub_name = 'gepuber_generated.epub'
      GEPUB::Builder.new {
        block.call
        resources {
          Dir.glob('*.css') {
            |f|
            file f
          }
          Dir.glob('img/*') {
            |f|
            if File.basename(f) == 'cover.jpg'
              cover_image f
            else
              file f
            end
          }

          ordered {
            Dir.glob('[0-9]*.{xhtml,html}') {
              |f|
              file f
              if table_of_contents[f]
                heading table_of_contents[f]
              end
            }
          }
        }
      }
    end
  end
end
