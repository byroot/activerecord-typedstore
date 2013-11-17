module ActiveRecord::TypedStore

  module AR32Fallbacks
    extend ActiveSupport::Concern

    included do
      cattr_accessor :virtual_attribute_methods
      self.virtual_attribute_methods = []
    end

    module ClassMethods

      def typed_store(store_attribute, dsl)
        _ar_32_fallback_accessors(store_attribute, dsl.accessors)
      end

      protected

      def define_virtual_attribute_method(name)
        virtual_attribute_methods << name
        define_attribute_method(name)
      end

      # ActiveModel override heavilly inspired from the original code
      def define_attribute_method(attr_name)
        return super unless virtual_attribute_methods.include?(attr_name)

        attribute_method_matchers.each do |matcher|
          method_name = matcher.method_name(attr_name)
          unless instance_method_already_implemented?(method_name)
            define_optimized_call generated_attribute_methods, method_name, matcher.method_missing_target, attr_name.to_s
          end
        end
        attribute_method_matchers_cache.clear
      end

      def _ar_32_fallback_accessors(store_attribute, accessors)
        accessors.each do |accessor|
          _ar_32_fallback_accessor(store_attribute, accessor)
        end
      end

      def _ar_32_fallback_accessor(store_attribute, key)
        define_method("#{key}=") do |value|
          write_store_attribute(store_attribute, key, value)
        end
        define_method(key) do
          read_store_attribute(store_attribute, key)
        end
      end

    end

    private

    def initialize_store_attribute(store_attribute)
      send("#{store_attribute}=", {}) unless send(store_attribute).is_a?(Hash)
      send(store_attribute)
    end

    def read_store_attribute(store_attribute, key)
      store = initialize_store_attribute(store_attribute)
      store[key]
    end

    def write_store_attribute(store_attribute, key, value)
      attribute_will_change!(store_attribute.to_s)
      send(store_attribute)[key] = value
    end

  end

  Extension.send(:include, AR32Fallbacks)
end
