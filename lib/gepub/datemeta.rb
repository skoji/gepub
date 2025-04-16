require 'rubygems'
require 'time'

module GEPUB
  class DateMeta < Meta
    # @rbs (String, String | Time, GEPUB::Metadata, ?Hash[untyped, untyped], ?Hash[untyped, untyped]) -> void
    def initialize(name, content, parent, attributes = {}, refiners = {})
      if content.is_a? String
        content = Time.parse(content)
      end
      super(name, content, parent, attributes, refiners)
    end

    # @rbs (Time) -> void
    def content=(date)
      if date.is_a? String
        date = Time.parse(date)
      end
      @content = date
    end

    # @rbs (?nil) -> String
    def to_s(_locale = nil)
      # date type don't have alternate scripts.
      @content.utc.iso8601
    end
  end
end
