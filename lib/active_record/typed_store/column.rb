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

      super(value)
    end

  end

end
