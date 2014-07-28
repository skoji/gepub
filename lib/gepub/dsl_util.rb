module GEPUB
  module DSLUtil
    UNASSIGNED = Object.new

    private
    def unassigned?(value)
      return value === UNASSIGNED
    end
  end
end

