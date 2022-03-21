# frozen_string_literal: true

require 'active_record/typed_store/field'

module ActiveRecord::TypedStore
  class DSL
    attr_reader :fields, :coder

    def initialize(store_name, options)
      @coder = options.fetch(:coder) { default_coder(store_name) }
      @store_name = store_name
      @prefix =
        case options[:prefix]
        when String, Symbol
          "#{options[:prefix]}_"
        when true
          "#{store_name}_"
        when false, nil
          ""
        else
          raise ArgumentError, "Unexpected type for prefix option. Expected string, symbol, or boolean"
        end
      @suffix =
        case options[:suffix]
        when String, Symbol
          "_#{options[:suffix]}"
        when true
          "_#{store_name}"
        when false, nil
          ""
        else
          raise ArgumentError, "Unexpected type for suffix option. Expected string, symbol, or boolean"
        end
      @accessors = if options[:accessors] == false
        {}
      elsif options[:accessors].is_a?(Array)
        options[:accessors].each_with_object({}) do |accessor_name, hash|
          hash[accessor_name] = accessor_key_for(accessor_name)
        end
      end
      @fields = {}
      yield self
    end

    if ActiveRecord.gem_version < Gem::Version.new('5.1.0')
      def default_coder(attribute_name)
        ActiveRecord::Coders::YAMLColumn.new
      end
    else
      def default_coder(attribute_name)
        ActiveRecord::Coders::YAMLColumn.new(attribute_name)
      end
    end

    def accessors
      @accessors || @fields.values.select(&:accessor).each_with_object({}) do |field, hash|
        hash[field.name] = accessor_key_for(field.name)
      end
    end

    delegate :keys, to: :@fields

    NO_DEFAULT_GIVEN = Object.new
    [:string, :text, :integer, :float, :time, :datetime, :date, :boolean, :decimal, :any].each do |type|
      define_method(type) do |name, **options|
        @fields[name] = Field.new(name, type, options)
      end
    end
    alias_method :date_time, :datetime

    private

    def accessor_key_for(name)
      "#{@prefix}#{name}#{@suffix}"
    end
  end
end
