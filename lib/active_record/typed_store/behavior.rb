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
  end
end
