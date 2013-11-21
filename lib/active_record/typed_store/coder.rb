module ActiveRecord::TypedStore

  class Coder < ::ActiveRecord::Store::IndifferentCoder

    class << self

      def create(store_class)
        Class.new(self) do
          @store_class = store_class
        end
      end

      def as_indifferent_hash(obj)
        return obj if obj.is_a?(@store_class)
        @store_class.new(obj)
      end

    end

  end

end
