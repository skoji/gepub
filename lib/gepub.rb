def ruby2_keywords(*)
end if RUBY_VERSION < "2.7" && !(defined? ruby2_keywords)

require 'gepub/version'
require 'gepub/dsl_util'
require 'gepub/xml_util'
require 'gepub/inspect_mixin'
require 'gepub/meta'
require 'gepub/datemeta'
require 'gepub/meta_array'
require 'gepub/metadata'
require 'gepub/metadata_add'
require 'gepub/manifest'
require 'gepub/spine'
require 'gepub/bindings'
require 'gepub/package'
require 'gepub/mime'
require 'gepub/item'
require 'gepub/book'
require 'gepub/book_add_item'
require 'gepub/builder_mixin'
require 'gepub/resource_builder'
require 'gepub/builder'






