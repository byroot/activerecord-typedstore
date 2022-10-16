# frozen_string_literal: true

module ActiveRecord::TypedStore
  class Type < ActiveRecord::Type::Serialized
    def initialize(typed_hash_klass, coder, subtype)
      @typed_hash_klass = typed_hash_klass
      super(subtype, coder)
    end

    [:deserialize, :type_cast_from_database, :type_cast_from_user].each do |method|
      define_method(method) do |value|
        if value.nil?
          hash = {}
        else
          hash = super(value)
        end

        @typed_hash_klass.new(hash)
      end
    end

    [:serialize, :type_cast_for_database].each do |method|
      define_method(method) do |value|
        return if value.nil?

        if value.respond_to?(:to_hash)
          super(value.to_hash)
        else
          raise ArgumentError, "ActiveRecord::TypedStore expects a hash as a column value, #{value.class} received"
        end
      end
    end

    def defaults
      @typed_hash_klass.defaults_hash
    end

    def default_value?(value)
      value == defaults
    end

    def changed_in_place?(raw_old_value, value)
      return false if value.nil?

      value != deserialize(raw_old_value)
    end
  end
end
