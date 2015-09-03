require 'active_record/typed_store/column'
require 'active_record/typed_store/dsl'
require 'active_record/typed_store/typed_hash'
require 'active_record/typed_store/coder'

module ActiveRecord::TypedStore
  module Extension
    extend ActiveSupport::Concern

    included do
      class_attribute :typed_stores, instance_accessor: false
      class_attribute :typed_store_attributes, instance_accessor: false

      self.typed_stores = {}
      self.typed_store_attributes = {}
    end

    module ClassMethods

      def typed_store(store_attribute, options = {}, &block)
        @dsl = DSL.new(options.fetch(:accessors, true), &block)

        serialize store_attribute, create_coder(store_attribute, @dsl.columns).new(options[:coder])
        typed_store_accessor(store_attribute, @dsl.accessors)

        register_typed_store_columns(store_attribute, @dsl.columns)

        @dsl
      end

      def typed_store_accessor(store_attribute, *keys)
        keys = keys.flatten

        _store_accessors_module.module_eval do
          keys.each do |key|
            define_method("#{key}=") do |value|
              write_typed_store_attribute(store_attribute, key, value)
            end

            define_method(key) do
              read_typed_store_attribute(store_attribute, key)
            end

          end
        end

        self.local_stored_attributes ||= {}
        self.local_stored_attributes[store_attribute] ||= []
        self.local_stored_attributes[store_attribute] |= keys
      end

      def columns
        @columns ||= super + add_user_provided_columns(@dsl.columns.select(&:accessor?))
      end

      def define_attribute_methods
        super
        store_accessors.each do |attribute|
          undefine_before_type_cast_method(attribute)
        end
        attribute_method_matchers_cache.clear
      end

      private

      def create_coder(store_attribute, columns)
        store_class = TypedHash.create(columns)
        const_set("#{store_attribute}_hash".camelize, store_class)
        coder_class = Coder.create(store_class)
        const_set("#{store_attribute}_coder".camelize, coder_class)
        coder_class
      end

      def register_typed_store_columns(store_attribute, columns)
        typed_stores[store_attribute] ||= {}
        typed_stores[store_attribute].merge!(columns.index_by(&:name))
        typed_store_attributes.merge!(columns.index_by { |c| c.name.to_s })
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
    end

    protected

    def attribute_method?(attr_name)
      super || store_attribute_method?(attr_name)
    end

    def store_attribute_method?(attr_name)
      return unless self.class.typed_store_attributes
      store_attribute = self.class.typed_store_attributes[attr_name]
      store_attribute && store_attribute.accessor?
    end

    def read_typed_store_attribute(store_attribute, key)
      accessor = store_accessor_for(store_attribute)
      accessor.read(self, store_attribute, key)
      #read_attribute(key)
    end

    def write_typed_store_attribute(store_attribute, key, value)
      column = store_column(store_attribute, key)
      if column.try(:type) == :datetime && self.class.time_zone_aware_attributes && value.respond_to?(:in_time_zone)
        value = value.in_time_zone
      end

      write_store_attribute(store_attribute, key, value)
      write_attribute(key, value)
    end

    private

    def match_attribute_method?(method_name)
      match = super
      return unless match
      return if match.target == 'attribute_before_type_cast'.freeze && store_attribute_method?(match.attr_name)
      match
    end

    def coder_for(attr_name)
      column = self.class.columns_hash[attr_name.to_s]
      return unless column && column.cast_type.is_a?(::ActiveRecord::Type::Serialized)
      column.cast_type.coder
    end

    def store_column(store_attribute, key)
      store = store_columns(store_attribute)
      store && store[key]
    end

    def store_columns(store_attribute)
      self.class.typed_stores.try(:[], store_attribute)
    end

  end
end
