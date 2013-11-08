module ActiveRecord::TypedStore

  module AR32Fallbacks
    extend ActiveSupport::Concern

    included do
      cattr_accessor :virtual_attribute_methods
      self.virtual_attribute_methods = []
    end

    module ClassMethods

      def typed_store(store_attribute, options={}, &block)
        dsl = super
        _ar_32_fallback_accessors(store_attribute, dsl.columns)
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

      def _ar_32_fallback_accessors(store_attribute, columns)
        _ar_32_fallback_initializer(store_attribute, columns)
        columns.each do |column|
          _ar_32_fallback_accessor(store_attribute, column)
        end
      end

      def _ar_32_fallback_initializer(store_attribute, columns)
        define_method(store_attribute) do
          initialized = "@_#{store_attribute}_initialized"
          unless instance_variable_get(initialized)
            store = read_attribute(store_attribute)
            store = initialize_store(store, columns)
            write_attribute(store_attribute, store)
            instance_variable_set(initialized, true)
          end
          read_attribute(store_attribute)
        end
      end

      def _ar_32_fallback_accessor(store_attribute, column)
        _ar_32_fallback_writer(store_attribute, column)
        _ar_32_fallback_reader(store_attribute, column)
      end

      def _ar_32_fallback_writer(store_attribute, column)
        define_method("#{column.name}_with_type_casting=") do |value|
          casted_value = column.cast(value)
          attribute_will_change!(column.name.to_s) if casted_value != send(column.name)
          send("#{column.name}_without_type_casting=", casted_value)
        end
        alias_method_chain "#{column.name}=", :type_casting
      end

      def _ar_32_fallback_reader(store_attribute, column)
        define_method(column.name) do
          send("#{store_attribute}=", {}) unless send(store_attribute).is_a?(Hash)
          store = send(store_attribute)

          store.has_key?(column.name) ? store[column.name] : column.default
        end
      end

    end

    def reload(*)
      _ar_32_reload_stores!
      super
    end

    private

    def _ar_32_reload_stores!
      self.class.stored_typed_attributes.keys.each do |store_attribute|
        instance_variable_set("@_#{store_attribute}_initialized", false)
      end
    end

  end

  ActiveRecord::Base.send(:include, AR32Fallbacks)
end
