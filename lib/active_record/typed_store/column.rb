module ActiveRecord::TypedStore

  class Column < ::ActiveRecord::ConnectionAdapters::Column
    attr_reader :array, :blank

    def initialize(name, type, options={})
      @name = name
      @type = type
      @array = options.fetch(:array, false)
      @default = extract_default(options.fetch(:default, nil))
      @null = options.fetch(:null, true)
      @blank = options.fetch(:blank, true)
      @accessor = options.fetch(:accessor, true)
    end

    def accessor?
      @accessor
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

    def extract_default(value)
      return value if (type == :string || type == :text) && value.nil?

      type_cast(value)
    end

    def type_cast(value, map=true)
      if array && (map || value.is_a?(Array))
        return [] if map && !value.is_a?(Array)
        return value.map{ |v| type_cast(v, false) }
      end

      if type == :string || type == :text
        return value.to_s unless value.nil? && (null || array)
      end

      if IS_AR_3_2 && type == :datetime && value.is_a?(DateTime)
        return super(value.iso8601)
      end

      defined?(super) ? super(value) : type_cast_from_database(value)
    end

  end

  if defined? ::ActiveRecord::Type
    BaseColumn = remove_const(:Column)

    class DecimalType < ::ActiveRecord::Type::Decimal
      def type_cast_from_database(value)
        value = value.to_s if value.is_a?(Float)
        super(value)
      end
    end

    class Column < BaseColumn
      CAST_TYPES = {
        boolean: ::ActiveRecord::Type::Boolean,
        integer: ::ActiveRecord::Type::Integer,
        string: ::ActiveRecord::Type::String,
        float: ::ActiveRecord::Type::Float,
        date: ::ActiveRecord::Type::Date,
        datetime: ::ActiveRecord::Type::DateTime,
        decimal: DecimalType,
        any: ::ActiveRecord::Type::Value,
      }

      def initialize(_, type, *)
        @cast_type = CAST_TYPES.fetch(type).new
        super
      end
    end
  end
end
