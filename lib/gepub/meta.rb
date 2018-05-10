require 'rubygems'
require 'nokogiri'

module GEPUB
  # Holds one metadata with refine meta elements.
  class Meta
    include DSLUtil
    attr_accessor :content
    attr_reader :name
    def initialize(name, content, parent, attributes= {}, refiners = {})
      @parent = parent
      @name = name
      @content = content
      @attributes = attributes
      @refiners = refiners
      @parent.register_meta(self) unless @parent.nil?
    end

    def [](x)
      @attributes[x]
    end

    def []=(x,y)
      @attributes[x] = y
    end

    def refiner_list(name)
      return @refiners[name].dup
    end

    def refiner_clear(name)
      if !@refiners[name].nil?
        @refiners[name].each {
          |refiner|
          @parent.unregister_meta(refiner)
        }
      end
      @refiners[name]= []
    end

    def refiner(name)
      refiner = @refiners[name]
      if refiner.nil? || refiner.size == 0
        nil
      else
        refiner[0]
      end
    end

    # add a refiner.
    def add_refiner(property, content, attributes = {})
      (@refiners[property] ||= []) <<  Meta.new('meta', content, @parent, { 'property' => property }.merge(attributes)) unless content.nil?
      self
    end

    # set a 'unique' refiner. all other refiners with same property will be removed.
    def refine(property, content, attributes = {})
      if !content.nil?
        refiner_clear(property)
        add_refiner(property, content, attributes)
      end
      self
    end

    ['title-type', 'identifier-type', 'display-seq', 'file-as', 'group-position', 'role'].each {
      |name|
      methodbase = name.sub('-','_')
      define_method(methodbase + '=') { |val| refine(name, val) }
      define_method('set_' + methodbase) { |val|
        warn "set_#{methodbase} is obsolete. use #{methodbase} instead."
        refine(name, val)
      }        
      define_method(methodbase, ->(value = UNASSIGNED) {
                      if unassigned?(value)
                        refiner(name)
                      else
                        refine(name,value)
                      end
                    })
    }

    def lang=(lang)
      @attributes['xml:lang'] = lang
    end

    def lang(lang = UNASSIGNED)
      if unassigned?(lang)
        @attributes['xml:lang']
      else
        self.lang=(lang)
      end
    end
    
    # add alternate script refiner.
    def add_alternates(alternates = {})
      alternates.each {
        |locale, content|
        add_refiner('alternate-script', content, { 'xml:lang' => locale })
      }
      self
    end

    def list_alternates
      list = refiner_list('alternate-script').map {
        |refiner|
        [ refiner['xml:lang'], refiner.content ]
      }
      Hash[*list.flatten]
    end

    def to_xml(builder, id_pool, ns = nil, additional_attr = {}, opf_version = '3.0')
      additional_attr ||= {}
      if @refiners.size > 0 && opf_version.to_f >= 3.0
        @attributes['id'] = id_pool.generate_key(:prefix => name) if @attributes['id'].nil?
      end

      # using __send__ to parametarize Namespace and content.
      target = ns.nil? || @name == 'meta' ? builder : builder[ns]
      attr = @attributes.reject{|k,v| v.nil?}.merge(additional_attr)
      if @content.nil?
        target.__send__(@name, attr)
      else
        target.__send__(@name, attr, self.to_s)
      end

      if @refiners.size > 0 && opf_version.to_f >= 3.0
        additional_attr['refines'] = "##{@attributes['id']}"
        @refiners.each {
          |k, ref_list|
          ref_list.each {
            |ref|
            ref.to_xml(builder, id_pool, nil, additional_attr)
          }
        }
      end
    end
    
    def to_s(locale=nil)
      localized = nil
      if !locale.nil?
        prefix = locale.sub(/^(.+?)-.*/, '\1')
        regex = Regexp.new("^((" + locale.split('-').join(')?-?(') + ")?)")
        candidates = @refiners['alternate-script'].select {
          |refiner|
          refiner['xml:lang'] =~ /^#{prefix}-?.*/
        }.sort_by {
          |x|
          x['xml:lang'] =~ regex; $1.size
        }.reverse
        localized = candidates[0].content if candidates.size > 0
      end
      (localized || self.content || super()).to_s
    end
  end
end
