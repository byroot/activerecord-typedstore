# frozen_string_literal: true

module ActiveRecord::TypedStore
  class Field
    attr_reader :array, :blank, :name, :default, :type, :null, :accessor, :type_sym

    def initialize(name, type, options={})
      type_options = options.slice(:scale, :limit, :precision)
      @type = lookup_type(type, type_options)
      @type_sym = type

      @accessor = options.fetch(:accessor, true)
      @name = name
      if options.key?(:default)
        @default = extract_default(options[:default])
      end
      @null = options.fetch(:null, true)
      @blank = options.fetch(:blank, true)
      @array = options.fetch(:array, false)
    end

    def has_default?
      defined?(@default)
    end

    def cast(value)
      casted_value = type_cast(value)
      if !blank
        casted_value = default if casted_value.blank?
      elsif !null
        casted_value = default if casted_value.nil?
      end
      casted_value
    end

    private

    TYPES = {
      boolean: ::ActiveRecord::Type::Boolean,
      integer: ::ActiveRecord::Type::Integer,
      string: ::ActiveRecord::Type::String,
      float: ::ActiveRecord::Type::Float,
      date: ::ActiveRecord::Type::Date,
      time: ::ActiveRecord::Type::Time,
      datetime: ::ActiveRecord::Type::DateTime,
      decimal: ::ActiveRecord::Type::Decimal,
      any: ::ActiveRecord::Type::Value,
    }

    def lookup_type(type, options)
      TYPES.fetch(type).new(**options)
    end

    def extract_default(value)
      # 4.2 workaround
      return value if (type_sym == :string || type_sym == :text) && value.nil?

      type_cast(value)
    end

    def type_cast(value, arrayize: true)
      if array && (arrayize || value.is_a?(Array))
        return [] if arrayize && !value.is_a?(Array)
        return value.map { |v| type_cast(v, arrayize: false) }
      end

      # 4.2 workaround
      if type_sym == :string || type_sym == :text
        return value.to_s unless value.blank? && (null || array)
      end

      if type.respond_to?(:cast)
        type.cast(value)
      else
        type.type_cast_from_user(value)
      end
    end
  end
end
