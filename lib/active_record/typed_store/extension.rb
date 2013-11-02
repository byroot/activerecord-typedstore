require 'active_record/typed_store/column'
require 'active_record/typed_store/dsl'

module ActiveRecord::TypedStore
  AR_VERSION = Gem::Version.new(ActiveRecord::VERSION::STRING)
  IS_AR_3_2 = AR_VERSION < Gem::Version.new('4.0')
  IS_AR_4_0 = AR_VERSION >= Gem::Version.new('4.0') && AR_VERSION < Gem::Version.new('4.1.0.beta')
  IS_AR_4_1 = AR_VERSION >= Gem::Version.new('4.1.0.beta')

  module Extension
    extend ActiveSupport::Concern

    included do
      class_attribute :stored_typed_attributes, instance_accessor: false
      self.stored_typed_attributes = {}
      if IS_AR_3_2
        require 'active_record/typed_store/ar_32_fallbacks'
        extend AR32Fallbacks
      end
    end

    module ClassMethods

      def typed_store(store_attribute, options={}, &block)
        dsl = DSL.new(&block)

        store(store_attribute, options.merge(accessors: dsl.column_names))

        stored_typed_attributes[store_attribute] ||= {}
        stored_typed_attributes[store_attribute].merge!(dsl.columns.index_by(&:name))

        if IS_AR_4_1
          after_initialize { initialize_store_attribute(store_attribute) }
        end

        dsl
      end

    end

    protected

    def write_store_attribute(store_attribute, key, value)
      casted_value = value
      if store_definition = self.class.stored_typed_attributes[store_attribute]
        if column_definition = store_definition[key]
          casted_value = column_definition.type_cast(value)
          if !column_definition.null && (value.nil? || casted_value.nil?)
            casted_value = column_definition.default
          end
        end
      end
      super(store_attribute, key, casted_value)
    end

    private

    def initialize_store_attribute(store_attribute)
      store = IS_AR_4_0 ? super : send(store_attribute)
      if columns = self.class.stored_typed_attributes[store_attribute]
        store = initialize_store(store, columns)
      end
      store
    end

    def initialize_store(store, columns)
      columns.each do |name, definition|
        if store.has_key?(name)
          store[name] = definition.type_cast(store[name])
        else
          store[name] = definition.default if definition.has_default?
        end
      end
      store
    end

  end
end
