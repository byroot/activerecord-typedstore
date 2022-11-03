# frozen_string_literal: true

module ActiveRecord::TypedStore
  module Behavior
    extend ActiveSupport::Concern

    module ClassMethods
      def define_attribute_methods
        super
        define_typed_store_attribute_methods
      end

      def undefine_attribute_methods # :nodoc:
        super if @typed_store_attribute_methods_generated
        @typed_store_attribute_methods_generated = false
      end

      def define_typed_store_attribute_methods
        return if @typed_store_attribute_methods_generated
        store_accessors.each do |attribute|
          define_attribute_method(attribute)
          undefine_before_type_cast_method(attribute)
        end
        @typed_store_attribute_methods_generated = true
      end

      def undefine_before_type_cast_method(attribute)
        # because it mess with ActionView forms, see #14.
        method = "#{attribute}_before_type_cast"
        undef_method(method) if method_defined?(method)
      end
    end

    def initialize(*)
      super
      mark_typed_stores_as_read
    end

    def init_with_attributes(*)
      super
      mark_typed_stores_as_read
      self
    end

    def changes
      changes = super
      self.class.store_accessors.each do |attr|
        if send("#{attr}_changed?")
          changes[attr] = [send("#{attr}_was"), send(attr)]
        end
      end
      changes
    end

    def clear_attribute_change(attr_name)
      return if self.class.store_accessors.include?(attr_name.to_s)
      super
    end

    def read_attribute(attr_name)
      if self.class.store_accessors.include?(attr_name.to_s)
        return public_send(attr_name)
      end
      super
    end

    def attribute?(attr_name)
      if self.class.store_accessors.include?(attr_name.to_s)
        value = public_send(attr_name)

        case value
        when true        then true
        when false, nil  then false
        else
          if value.respond_to?(:zero?)
            !value.zero?
          else
            !value.blank?
          end
        end
      else
        super
      end
    end

    private

    def mark_typed_stores_as_read
      # Active Model doesn't check wether attributes have been changed
      # in place unless they have been read first.
      # That is a sensible thing to do given no standard rails attribute
      # can possibly be mutated before being read (unless you changed the coder somehow).
      #
      # But in typed store we have extensive default values, so if a record with the column default
      # might still be considered dirty.
      #
      # To work around this we always read all the stores on initialization so that they're
      # all considered for in-place changes.
      #
      # It's not ideal as deserialization may be wasteful.
      self.class.typed_stores.each_key do |store_name|
        name = store_name.to_s
        if @attributes.key?(name)
          attribute = @attributes[name]
          # We only mark the store as read if it has the default column value to not waste performance
          if attribute.value_before_type_cast == self.class.columns_hash[name].default
            attribute.value # mark the attribute as read
          end
        end
      end
    end
  end
end
