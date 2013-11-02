module ActiveRecord::TypedStore

  module AR32Fallbacks

    def typed_store(store_attribute, options={}, &block)
      dsl = super
      _ar_32_fallback_accessors(store_attribute, dsl.columns)
    end

    protected

    def _ar_32_fallback_accessors(store_attribute, columns)
      _ar_32_fallback_initializer(store_attribute, columns)
      columns.each do |column|
        _ar_32_fallback_accessor(store_attribute, column)
      end
    end

    def _ar_32_fallback_initializer(store_attribute, columns)
      after_initialize { initialize_store_attribute(store_attribute) }
    end

    def _ar_32_fallback_accessor(store_attribute, column)
      _ar_32_fallback_writer(store_attribute, column)
      _ar_32_fallback_reader(store_attribute, column)
    end

    def _ar_32_fallback_writer(store_attribute, column)
      define_method("#{column.name}_with_type_casting=") do |value|
        casted_value = column.type_cast(value)
        casted_value = column.default if casted_value.nil? && !column.null
        self.send("#{column.name}_without_type_casting=", casted_value)
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

end
