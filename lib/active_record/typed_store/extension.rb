# frozen_string_literal: true

require 'active_record/typed_store/dsl'
require 'active_record/typed_store/behavior'
require 'active_record/typed_store/type'
require 'active_record/typed_store/typed_hash'
require 'active_record/typed_store/identity_coder'

module ActiveRecord::TypedStore
  module Extension
    def typed_store(store_attribute, options={}, &block)
      unless self < Behavior
        include Behavior
        class_attribute :typed_stores, :store_accessors, instance_accessor: false

        def inherited(sub_class)
          super(sub_class)

          if self.respond_to? :typed_stores
            # Copy the store to the sub class to avoid mutation of the store in parent class
            sub_class.typed_stores = self.typed_stores.map do |store_attribute, store|
              new_store = store.dup
              new_store.instance_variable_set(:'@fields', store.fields.dup)
              [store_attribute, new_store]
            end.to_h
          end
        end
      end

      self.typed_stores ||= {}
      store_options = options.slice(:prefix, :suffix)
      dsl = self.typed_stores[store_attribute] || DSL.new(store_attribute, options)
      dsl.store_accessors(options, &block)
      self.typed_stores[store_attribute] = dsl
      self.store_accessors = typed_stores.each_value.flat_map { |d| d.accessors.values }.map { |a| -a.to_s }.to_set

      typed_klass = TypedHash.create(dsl.fields.values)
      const_name = "#{store_attribute}_hash".camelize
      if const_defined?(const_name) && const_get(const_name).to_s == "#{self}/#{store_attribute}_hash".camelize
        remove_const(const_name)
      end
      const_set(const_name, typed_klass)

      if ActiveRecord.version >= Gem::Version.new('6.1.0.alpha')
        attribute(store_attribute) do |subtype|
          subtype = subtype.subtype if subtype.is_a?(Type)
          Type.new(typed_klass, dsl.coder, subtype)
        end
      else
        decorate_attribute_type(store_attribute, :typed_store) do |subtype|
          Type.new(typed_klass, dsl.coder, subtype)
        end
      end
      store_accessor(store_attribute, dsl.accessors.keys, **store_options)

      dsl.accessors.each do |accessor_name, accessor_key|
        define_method("#{accessor_key}_changed?") do
          send("#{store_attribute}_changed?") &&
            send(store_attribute)[accessor_name] != send("#{store_attribute}_was")[accessor_name]
        end

        define_method("#{accessor_key}_was") do
          send("#{store_attribute}_was")[accessor_name]
        end

        define_method("restore_#{accessor_key}!") do
          send("#{accessor_key}=", send("#{accessor_name}_was"))
        end
      end
    end
  end
end
