module GEPUB
  module InspectMixin
    def inspect
      result = instance_variables.each
        .with_object({}) { |name, h| h[name] = instance_variable_get(name) }
        .reject { |name, value| value.nil? }
        .map { |name, value|
          case value
          when true, false, Symbol, Numeric, Array, Hash
            "#{name}=#{value.inspect}"
          when String
            if value.length > 80
              "#{name}=(omitted)"
            else
              "#{name}=#{value.inspect}"
            end
          else
            "#{name}=#<#{value.class.name}>"
          end
        }
        .join(' ')

      "#<#{self.class.name} " + result + '>'
    end
  end
end
