module ActiveRecord::TypedStore

  module AR41Fallbacks

    private

    module HashAccessorPatch

      def self.extended(hash_accessor)
        hash_accessor.singleton_class.alias_method_chain :prepare, :initialization
      end

      protected

      def prepare_with_initialization(object, store_attribute)
        prepare_without_initialization(object, store_attribute)
        object.send(:initialize_store_attribute, store_attribute)
      end

    end

    ActiveRecord::Store::HashAccessor.extend(HashAccessorPatch)
    ActiveRecord::Store::IndifferentHashAccessor.extend(HashAccessorPatch)
  end

end
