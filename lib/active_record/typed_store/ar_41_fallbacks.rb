module ActiveRecord::TypedStore

  module AR41Fallbacks

    def reload(*)
      _ar_41_reload_stores!
      super
    end

    private

    def _ar_41_reload_stores!
      self.class.stored_typed_attributes.keys.each do |store_attribute|
        instance_variable_set("@_#{store_attribute}_initialized", false)
      end
    end

    module HashAccessorPatch

      def self.extended(hash_accessor)
        hash_accessor.singleton_class.alias_method_chain :prepare, :initialization
      end

      protected

      def prepare_with_initialization(object, store_attribute)
        prepare_without_initialization(object, store_attribute)

        initialized = "@_#{store_attribute}_initialized"
        unless object.instance_variable_get(initialized)
          store = object.send(:initialize_store_attribute, store_attribute)
          object.send("#{store_attribute}=", store)
          object.instance_variable_set(initialized, true)
        end

      end

    end

    ActiveRecord::Store::HashAccessor.extend(HashAccessorPatch)
    ActiveRecord::Store::IndifferentHashAccessor.extend(HashAccessorPatch)
  end

  ActiveRecord::Base.send(:include, AR41Fallbacks)
end
