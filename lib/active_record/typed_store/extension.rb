require 'active_record/typed_store/column'
require 'active_record/typed_store/dsl'

module ActiveRecord::TypedStore
  module Extension
    extend ActiveSupport::Concern

    included do
      class_attribute :stored_typed_attributes, instance_accessor: false
      self.stored_typed_attributes = {}
    end

    module ClassMethods

      def typed_store(store_attribute, options={}, &block)
        dsl = DSL.new(&block)

        store(store_attribute, options.merge(accessors: dsl.column_names))
        stored_typed_attributes[store_attribute] ||= {}
        stored_typed_attributes[store_attribute].merge!(dsl.columns.index_by(&:name))
      end

    end

    protected

    def write_store_attribute(store_attribute, key, value)
      casted_value = value
      if store_definition = self.class.stored_typed_attributes[store_attribute]
        if column_definition = store_definition[key]
          casted_value = column_definition.type_cast(value)
        end
      end
      super(store_attribute, key, casted_value)
    end

    private

    def initialize_store_attribute(store_attribute)
      attribute = super
      if columns = self.class.stored_typed_attributes[store_attribute]
        columns.each do |name, definition|
          if !attribute.has_key?(name) && definition.has_default?
            attribute[name] = definition.default 
          end
        end
      end
      attribute
    end

  end
end
