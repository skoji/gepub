module GEPUB
  class ResourceBuilder
    include BuilderMixin
    class ResourceItem
      attr_reader :item
      def initialize(item)
        @item = item
      end

      def apply_one_to_multi
        true
      end

      def media_type(val)
        @item.set_media_type(val)
      end
      
      def method_missing(name, *args, &block)
        @item.send(name.to_sym, *args, &block)
      end
    end
    
    def initialize(book, attributes = {},  &block)
      @last_defined_item = nil
      @book = book
      @dir_prefix = ""
      @file_postprocess = {}
      @file_preprocess = {}
      @files_postprocess = {}
      @files_preprocess = {}
      current_wd = Dir.getwd
      Dir.chdir(attributes[:workdir]) unless attributes[:workdir].nil?
      instance_eval(&block)
      Dir.chdir current_wd
      true
    end

    def ordered(&block)
      @book.ordered {
        instance_eval(&block)
      }
    end

    def file(val)
      raise "can't specify multiple files on file keyword" if Hash === val && val.length > 1

      @file_preprocess.each {
        |k,p|
        p.call
      }
      @last_defined_item = ResourceItem.new(create_one_file(val))
      @file_postprocess.each {
        |k,p|
        p.call
      }
    end

    def files(*arg)
      arg = arg[0] if arg.size == 1 && Hash === arg[0]
      @files_preprocess.each {
        |k,p|
        p.call
      }
      @last_defined_item = arg.map {
        |val|
        ResourceItem.new(create_one_file(val))
      }
      @files_postprocess.each {
        |k,p|
        p.call
      }
    end

    def page_spread_left
      itemref = @book.spine.itemref_by_id[@last_defined_item.item.id]
      raise 'page_spread_left should be called inside ordered' if (itemref.nil?)
      itemref.page_spread_left
    end

    def page_spread_right
      itemref = @book.spine.itemref_by_id[@last_defined_item.item.id]
      raise 'page_spread_right should be called inside ordered' if (itemref.nil?)
      itemref.page_spread_right
    end

    def rendition_layout val
      itemref = @book.spine.itemref_by_id[@last_defined_item.item.id]
      raise 'rendition should be called inside ordered' if (itemref.nil?)
      itemref.rendition_layout = val
    end
    def rendition_orientation val
      itemref = @book.spine.itemref_by_id[@last_defined_item.item.id]
      raise 'rendition should be called inside ordered' if (itemref.nil?)
      itemref.rendition_orientation = val
    end
    def rendition_spread val
      itemref = @book.spine.itemref_by_id[@last_defined_item.item.id]
      raise 'rendition should be called inside ordered' if (itemref.nil?)
      itemref.rendition_spread = val
    end

    def linear val
      itemref = @book.spine.itemref_by_id[@last_defined_item.item.id]
      raise 'linear should be called inside ordered' if (itemref.nil?)
      itemref.linear = val
    end
    
    def glob(arg)
      files(*Dir.glob(arg).select{|x| !File.directory?(x)} )
    end

    def import(conf, args = {})
      dir_prefix_org = @dir_prefix
      @dir_prefix = args[:dir_prefix] || ""
      Dir.chdir(File.dirname(conf)) {
        instance_eval(File.new(File.basename(conf)).read)
      }
      @dir_prefix = dir_prefix_org
    end

    def add_resource_dir(name)
      import "#{name}/resources.conf", :dir_prefix => name
    end

    def add_resource_dirs(dirs)
      dirs.each do
        |dir|
        add_resource_dir dir
      end
    end
    
    def cover_image(val)
      file(val)
      @last_defined_item.cover_image
    end

    def nav(val)
      file(val)
      @last_defined_item.nav
    end

    def heading(text, id = nil)
      @last_defined_item.toc_text_with_id(text, id)
    end

    def id(the_id)
      @last_defined_item.id = the_id
    end

    def with_media_type(*type)
      raise 'with_media_type needs block.' unless block_given?
      @file_postprocess['with_media_type'] = Proc.new { media_type(*type) }
      @files_postprocess['with_media_type'] = Proc.new { media_type(*type) }
      yield 
      @file_postprocess.delete('with_media_type')
      @files_postprocess.delete('with_media_type')
    end

    def fallback_group
      raise 'fallback_group needs block.' unless block_given?
      count = 0
      before = nil

      @files_preprocess['fallback_group'] = Proc.new { raise "can't use files within fallback_group" }

      @file_preprocess['fallback_group'] = Proc.new {
        before = @last_defined_item
      }

      @file_postprocess['fallback_group'] = Proc.new {
        if count > 0
          before.item.set_fallback(@last_defined_item.item.id)
        end
        count += 1
      }
      yield
      @files_preprocess.delete('fallback_group')
      @file_postprocess.delete('fallback_group')
      @file_preprocess.delete('fallback_group')
    end

    def fallback_chain_files(*arg)
      files(*arg)
      @last_defined_item.inject(nil) {
        |item1, item2|
        if !item1.nil?
          item1.item.set_fallback(item2.item.id)
        end
        item2
      }
    end

    def handles(media_type)
      @last_defined_item.is_handler_of(media_type)
    end

    private

    def create_one_file(val)
      name = val
      io = val if (String === val && !val.start_with?('http'))
      if Hash === val 
        name = val.first[0]
        io = val.first[1]
      end
      if Array === val
        name = val[0]
        io = val[1]
      end
      name = "#{@dir_prefix}/#{name}" if !@dir_prefix.nil? && @dir_prefix.size > 0 && !name.start_with?('http')
      @book.add_item(name, io)
    end
  end    

end
