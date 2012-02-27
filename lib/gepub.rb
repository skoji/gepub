if !({}.respond_to? 'key')
  class Hash
    def key(x)
      index(x)
    end
  end
end

require 'gepub/version'
require 'gepub/xml_util'
require 'gepub/meta'
require 'gepub/datemeta'
require 'gepub/metadata'
require 'gepub/manifest'
require 'gepub/spine'
require 'gepub/package'
require 'gepub/item'
require 'gepub/book'
require 'gepub/builder_mixin'
require 'gepub/resource_builder'
require 'gepub/builder'





