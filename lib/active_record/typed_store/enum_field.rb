# frozen_string_literal: true

require 'active_record/typed_store/field'

module ActiveRecord::TypedStore
  class EnumField < Field
    attr_reader :enum_values, :enum_prefix

    def initialize(name, values:, _prefix: false, **options)
      pairs = values.respond_to?(:each_pair) ? values.each_pair : values.each_with_index
      @enum_values = pairs.each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |(k, v), h|
        h[k] = v
      end
      @enum_prefix = resolve_prefix(name, _prefix)
      super(name, :enum, **options.slice(:default))
    end

    def register_accessors(base, key:)
      return unless key

      enum_values.each do |value, integer|
        method_base = "#{enum_prefix}#{value}"
        base.define_method("#{method_base}?") { send(key) == integer }
        base.define_method("#{method_base}!") { update!(key => integer) }
      end
    end

    private

    def lookup_type(*) = nil

    def type_cast(value, arrayize: true)
      enum_values.fetch(value) do
        value if enum_values.value?(value)
      end
    end

    def resolve_prefix(name, prefix)
      case prefix
      when true then "#{name}_"
      when false, nil then ""
      else "#{prefix}_"
      end
    end
  end
end
