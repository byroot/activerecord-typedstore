module ActiveRecord
  module Type
    class Serialized

      private

      alias_method :orig_default_value?, :default_value?

      def default_value?(value)
        return false if coder.is_a?(ActiveRecord::TypedStore::Coder) && coder.store_defaults

        orig_default_value?(value)
      end
    end
  end
end