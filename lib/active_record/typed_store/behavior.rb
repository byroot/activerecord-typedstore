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

    if ActiveRecord.version.segments.first >= 7
      def attribute_names_for_partial_inserts
        # Contrary to all vanilla Rails types, typedstore attribute have an inherent default
        # value that doesn't match the database column default.
        # As such we need to insert them on partial inserts even if they weren't changed.
        super | self.class.typed_stores.keys.map(&:to_s)
      end

      def attribute_names_for_partial_updates
        # On partial updates we shouldn't need to force stores to be persisted. However since
        # we weren't persisting them for a while on insertion, we now need to gracefully deal
        # with existing records that may have been persisted with a `NULL` store
        # We use `blank?` as an heuristic to detect these.
        super | self.class.typed_stores.keys.map(&:to_s).select do |store|
          has_attribute?(store) && read_attribute_before_type_cast(store).blank?
        end
      end
    else
      # Rails 6.1 capability
      def attribute_names_for_partial_writes
        super | self.class.typed_stores.keys.map(&:to_s).select do |store|
          has_attribute?(store) && read_attribute_before_type_cast(store).blank?
        end
      end
    end
  end
end
