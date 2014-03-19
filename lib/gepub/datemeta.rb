require 'rubygems'
require 'time'

module GEPUB
  class DateMeta < Meta
    def initialize(name, content, parent, attributes = {}, refiners = {})
      if content.is_a? String
        content = Time.parse(content)
      end
      super(name, content, parent, attributes, refiners)
    end

    def content=(date)
      if date.is_a? String
        date = Time.parse(date)
      end
      @content = date
    end

    def to_s(locale = nil)
      # date type don't have alternate scripts.
      @content.utc.iso8601
    end
  end
end
