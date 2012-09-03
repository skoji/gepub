module GEPUB
  module BuilderMixin
    def method_missing(name, *args, &block)
      if Array === @last_defined_item &&
          @last_defined_item.size > 0 &&
          @last_defined_item[0].respond_to?(name.to_sym)

        if !(@last_defined_item[0].apply_one_to_multi ||
             @last_defined_item.size != 1) &&
            @last_defined_item.size != args.size
          warn "appling #{args} to #{@last_defined_item}: length differs."
        end

        @last_defined_item.each_with_index {
          |item, i|
          if item.apply_one_to_multi && args.size == 1
            item.send(name, args[0])
          elsif !args[i].nil?
            item.send(name, args[i])
          end
        }
      elsif @last_defined_item.respond_to?(name.to_sym)
        @last_defined_item.send(name, *args, &block)
      else
        super
      end
    end
  end
end
