require 'active_record/typed_store/column'
require 'active_record/typed_store/dsl'

module ActiveRecord::TypedStore
  AR_VERSION = Gem::Version.new(ActiveRecord::VERSION::STRING)
  IS_AR_3_2 = AR_VERSION < Gem::Version.new('4.0')
  IS_AR_4_1 = AR_VERSION >= Gem::Version.new('4.1.0.beta')

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

        dsl.column_names.each { |c| define_virtual_attribute_method(c.to_s) }
        dsl.column_names.each { |c| define_store_attribute_queries(store_attribute, c) }

        super(store_attribute, dsl) if defined?(super)

        dsl
      end

      private

      def define_store_attribute_queries(store_attribute, column_name)
        define_method("#{column_name}?") do
          query_store_attribute(store_attribute, column_name)
        end
      end

    end

    def reload(*)
      reload_stores!
      super
    end

    protected

    def write_store_attribute(store_attribute, key, value)
      previous_value = read_store_attribute(store_attribute, key)
      casted_value = cast_store_attribute(store_attribute, key, value)
      attribute_will_change!(key.to_s) if casted_value != previous_value
      super(store_attribute, key, casted_value)
    end

    private

    def cast_store_attribute(store_attribute, key, value)
      column = store_column_definition(store_attribute, key)
      column ? column.cast(value) : value
    end

    def store_column_definition(store_attribute, key)
      store_definition = self.class.stored_typed_attributes[store_attribute]
      store_definition && store_definition[key]
    end

    def if_store_uninitialized(store_attribute)
      initialized = "@_#{store_attribute}_initialized"
      unless instance_variable_get(initialized)
        yield
        instance_variable_set(initialized, true)
      end
    end

    def reload_stores!
      self.class.stored_typed_attributes.keys.each do |store_attribute|
        instance_variable_set("@_#{store_attribute}_initialized", false)
      end
    end

    def initialize_store_attribute(store_attribute)
      store = defined?(super) ? super : send(store_attribute)
      store.tap do |store|
        if_store_uninitialized(store_attribute) do
          if columns = self.class.stored_typed_attributes[store_attribute]
            initialize_store(store, columns.values)
          end
        end
      end
    end

    def initialize_store(store, columns)
      columns.each do |column|
        if store.has_key?(column.name)
          store[column.name] = column.cast(store[column.name])
        else
          store[column.name] = column.default if column.has_default?
        end
      end
      store
    end

    # heavilly inspired from ActiveRecord::Base#query_attribute
    def query_store_attribute(store_attribute, key)
      value = read_store_attribute(store_attribute, key)

      case value
      when true        then true
      when false, nil  then false
      else
        column = store_column_definition(store_attribute, key)
        if column.nil?
          if Numeric === value || value !~ /[^0-9]/
            !value.to_i.zero?
          else
            return false if ActiveRecord::ConnectionAdapters::Column::FALSE_VALUES.include?(value)
            !value.blank?
          end
        elsif column.number?
          !value.zero?
        else
          !value.blank?
        end
      end
    end

  end

  require 'active_record/typed_store/ar_32_fallbacks' if IS_AR_3_2
  require 'active_record/typed_store/ar_41_fallbacks' if IS_AR_4_1
  unless IS_AR_3_2
    ActiveModel::AttributeMethods::ClassMethods.send(:alias_method, :define_virtual_attribute_method, :define_attribute_method)
  end

end
