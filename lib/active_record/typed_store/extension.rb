require 'active_record/typed_store/dsl'
require 'active_record/typed_store/type'
require 'active_record/typed_store/typed_hash'

module ActiveRecord::TypedStore
  module Extension
    extend ActiveSupport::Concern

    included do
      class_attribute :typed_stores
    end

    module ClassMethods
      def store_accessors
        return [] unless typed_stores
        typed_stores.values.map(&:accessors).flatten
      end

      def typed_store(store_attribute, options={}, &block)
        dsl = find_or_initialize_dsl(store_attribute, options, &block)

        self.typed_stores ||= {}
        self.typed_stores = typed_stores.deep_dup
        self.typed_stores[store_attribute] = dsl

        typed_klass = TypedHash.create(dsl.fields.values)
        const_name = "#{store_attribute}_hash".camelize
        send(:remove_const, const_name) if const_defined?(const_name)
        const_set(const_name, typed_klass)
        decorate_attribute_type(store_attribute, :typed_store) do |subtype|
          Type.new(typed_klass, dsl.coder, subtype)
        end
        store_accessor(store_attribute, dsl.accessors)

        return unless @exdsl_accessors
        extend_accessors = dsl.accessors - @exdsl_accessors
        extend_typed_store_attribute_methods extend_accessors
      end

      def define_attribute_methods
        super
        define_typed_store_attribute_methods if typed_stores
      end

      def undefine_attribute_methods # :nodoc:
        super if @typed_store_attribute_methods_generated
        @typed_store_attribute_methods_generated = false
      end

      def define_typed_store_attribute_methods
        return if @typed_store_attribute_methods_generated
        extend_typed_store_attribute_methods store_accessors
      end

      def undefine_before_type_cast_method(attribute)
        # because it mess with ActionView forms, see #14.
        method = "#{attribute}_before_type_cast"
        undef_method(method) if method_defined?(method)
      end

      protected

      def extend_typed_store_attribute_methods(*attr_names)
        return if attr_names.blank?
        attr_names.flatten.each do |attribute|
          define_attribute_method(attribute.to_s)
          undefine_before_type_cast_method(attribute)
        end
        @exdsl_accessors = nil if @exdsl_accessors
        @typed_store_attribute_methods_generated = true
      end

      private

      def find_or_initialize_dsl(store_attribute, options)
        dsl = typed_stores && typed_stores[store_attribute]
        if dsl.present?
          @exdsl_accessors = store_accessors
          dsl = dsl.clone
        end
        dsl ||= DSL.new(store_attribute, options)
        yield dsl
        dsl
      end
    end

    def clear_attribute_change(attr_name)
      return if self.class.store_accessors.include?(normalize_attribute(attr_name))
      super
    end

    def read_attribute(attr_name)
      if self.class.store_accessors.include?(normalize_attribute(attr_name))
        return public_send(attr_name)
      end
      super
    end

    def write_store_attribute(store_attribute, key, value)
      if typed_stores && typed_stores[store_attribute]
        prev_value = read_store_attribute(store_attribute, key)
        new_value = typed_stores[store_attribute].fields[key].cast(value)
        attribute_will_change!(key.to_s) if new_value != prev_value
      end

      super
    end

    def query_attribute(attr_name)
      if self.class.store_accessors.include?(attr_name.to_sym)
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

    def normalize_attribute(attr)
      case attr
      when Symbol
        attr
      else
        attr.to_s.to_sym
      end
    end
  end
end
