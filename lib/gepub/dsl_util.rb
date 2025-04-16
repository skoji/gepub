module GEPUB
  module DSLUtil
    UNASSIGNED = Object.new

    private
    # @rbs (String | Time | Integer) -> bool
    def unassigned?(value)
      return value === UNASSIGNED
    end
  end
end

