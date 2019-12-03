# frozen_string_literal: true

module ActiveRecord::TypedStore
  class TypedHash < HashWithIndifferentAccess

    class << self
      attr_reader :fields

      def create(fields)
        Class.new(self) do
          @fields = fields.index_by { |c| c.name.to_s }
        end
      end

      def defaults_hash
        Hash[fields.values.select(&:has_default?).map { |c| [c.name, c.default] }]
      end
    end

    delegate :with_indifferent_access, to: :to_h
    delegate :slice, :except, :without, to: :with_indifferent_access

    def initialize(constructor={})
      super()
      update(defaults_hash)
      update(constructor.to_h) if constructor.respond_to?(:to_h)
    end

    def []=(key, value)
      super(key, cast_value(key, value))
    end
    alias_method :store, :[]=

    def merge!(other_hash)
      other_hash.each_pair do |key, value|
        if block_given? && key?(key)
          value = yield(convert_key(key), self[key], value)
        end
        self[convert_key(key)] = convert_value(value)
      end
      self
    end
    alias_method :update, :merge!

    private

    delegate :fields, :defaults_hash, to: 'self.class'

    def cast_value(key, value)
      key = convert_key(key)
      field = fields[key]
      return value unless field

      casted_value = field.cast(value)

      if casted_value.nil? && !field.null && field.has_default?
        return field.default
      end

      casted_value
    end
  end
end
