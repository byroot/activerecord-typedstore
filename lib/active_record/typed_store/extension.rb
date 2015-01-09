require 'active_record/typed_store/column'
require 'active_record/typed_store/dsl'
require 'active_record/typed_store/typed_hash'

module ActiveRecord::TypedStore
  AR_VERSION = Gem::Version.new(ActiveRecord::VERSION::STRING)
  IS_AR_3_2 = AR_VERSION < Gem::Version.new('4.0')
  IS_AR_4_1 = AR_VERSION >= Gem::Version.new('4.1') && AR_VERSION < Gem::Version.new('4.2.0-rc1')
  IS_AR_4_2 = AR_VERSION >= Gem::Version.new('4.2.0-rc1')

  module Extension
    extend ActiveSupport::Concern

    included do
      class_attribute :typed_stores, instance_accessor: false
      class_attribute :typed_store_attributes, instance_accessor: false
    end

    module ClassMethods

      def typed_store(store_attribute, options={}, &block)
        dsl = DSL.new(options.fetch(:accessors, true), &block)

        serialize store_attribute, create_coder(store_attribute, dsl.columns).new(options[:coder])
        store_accessor(store_attribute, dsl.accessors)

        register_typed_store_columns(store_attribute, dsl.columns)
        super(store_attribute, dsl) if defined?(super)

        dsl.accessors.each { |c| define_store_attribute_queries(store_attribute, c) }

        dsl
      end

      def define_attribute_methods
        super
        define_typed_store_attribute_methods
      end

      def undefine_attribute_methods # :nodoc:
        super if @typed_store_attribute_methods_generated
        @typed_store_attribute_methods_generated = false
      end

      private

      def create_coder(store_attribute, columns)
        store_class = TypedHash.create(columns)
        const_set("#{store_attribute}_hash".camelize, store_class)
        Coder.create(store_class)
      end

      def register_typed_store_columns(store_attribute, columns)
        self.typed_stores ||= {}
        self.typed_store_attributes ||= {}
        typed_stores[store_attribute] ||= {}
        typed_stores[store_attribute].merge!(columns.index_by(&:name))
        typed_store_attributes.merge!(columns.index_by { |c| c.name.to_s })
      end

      def define_typed_store_attribute_methods
        return if @typed_store_attribute_methods_generated
        store_accessors.each do |attribute|
          define_virtual_attribute_method(attribute)
          undefine_before_type_cast_method(attribute)
        end
        @typed_store_attribute_methods_generated = true
      end

      def undefine_before_type_cast_method(attribute)
        # because it mess with ActionView forms, see #14.
        method = "#{attribute}_before_type_cast"
        undef_method(method) if method_defined?(method)
      end

      def store_accessors
        return [] unless typed_store_attributes
        typed_store_attributes.values.select(&:accessor?).map(&:name).map(&:to_s)
      end

      def create_time_zone_conversion_attribute?(name, column)
        column ||= typed_store_attributes[name]
        super(name, column)
      end

      def define_store_attribute_queries(store_attribute, column_name)
        define_method("#{column_name}?") do
          query_store_attribute(store_attribute, column_name)
        end
      end

    end

    protected

    if IS_AR_4_2
      def attribute_method?(attr_name)
        super || store_attribute_method?(attr_name)
      end
    end

    def store_attribute_method?(attr_name)
      return unless self.class.typed_store_attributes
      store_attribute = self.class.typed_store_attributes[attr_name]
      store_attribute && store_attribute.accessor?
    end

    def write_store_attribute(store_attribute, key, value)
      column = store_column(store_attribute, key)
      if column.try(:type) == :datetime && self.class.time_zone_aware_attributes && value.respond_to?(:in_time_zone)
        value = value.in_time_zone
      end

      previous_value = read_store_attribute(store_attribute, key)
      new_value = column ? column.type_cast(value) : value
      attribute_will_change!(key.to_s) if new_value != previous_value
      super
    end

    private

    if IS_AR_4_2
      def match_attribute_method?(method_name)
        match = super
        return unless match
        return if match.target == 'attribute_before_type_cast'.freeze && store_attribute_method?(match.attr_name)
        match
      end

      def coder_for(attr_name)
        column = self.class.columns_hash[attr_name.to_s]
        return unless column.cast_type.is_a?(::ActiveRecord::Type::Serialized)
        column.cast_type.coder
      end
    else
      def coder_for(attr_name)
        self.class.serialized_attributes[attr_name]
      end
    end

    def write_attribute(attr_name, value)
      if coder = coder_for(attr_name)
        if coder.is_a?(ActiveRecord::TypedStore::Coder)
          return super(attr_name, coder.as_indifferent_hash(value))
        end
      end

      super
    end

    def keys_for_partial_write
      super & self.class.column_names
    end

    def store_column(store_attribute, key)
      store = store_columns(store_attribute)
      store && store[key]
    end

    def store_columns(store_attribute)
      self.class.typed_stores.try(:[], store_attribute)
    end

    # heavilly inspired from ActiveRecord::Base#query_attribute
    def query_store_attribute(store_attribute, key)
      value = read_store_attribute(store_attribute, key)

      case value
      when true        then true
      when false, nil  then false
      else
        column = store_column(store_attribute, key)

        if column.number?
          !value.zero?
        else
          !value.blank?
        end
      end
    end

  end

  require 'active_record/typed_store/ar_32_fallbacks' if IS_AR_3_2
  require 'active_record/typed_store/coder'

  unless IS_AR_3_2
    ActiveModel::AttributeMethods::ClassMethods.send(:alias_method, :define_virtual_attribute_method, :define_attribute_method)
  end

end
