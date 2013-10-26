require 'active_record/typed_store/column'
require 'active_record/typed_store/dsl'

module ActiveRecord::TypedStore
  IS_AR_4 = Gem::Version.new(ActiveRecord::VERSION::STRING) >= Gem::Version.new('4.0')

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

        unless IS_AR_4
          after_initialize {
            initialize_store_attribute(store_attribute)
          }

          dsl.columns.each do |column|
            define_method("#{column.name}_with_type_casting=") do |value|
              self.send("#{column.name}_without_type_casting=", column.type_cast(value))
            end
            alias_method_chain "#{column.name}=", :type_casting


            define_method(column.name) do
              send("#{store_attribute}=", {}) unless send(store_attribute).is_a?(Hash)
              store = send(store_attribute)
              store.has_key?(column.name) ? store[column.name] : column.default
            end
          end
        end
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
      attribute = IS_AR_4 ? super : send(store_attribute)
      if columns = self.class.stored_typed_attributes[store_attribute]
        columns.each do |name, definition|
          if attribute.has_key?(name)
            attribute[name] = definition.type_cast(attribute[name])
          else
            attribute[name] = definition.default if definition.has_default?
          end
        end
      end
      attribute
    end

  end
end
