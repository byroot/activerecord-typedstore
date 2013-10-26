module ActiveRecord::TypedStore

  class Column < ::ActiveRecord::ConnectionAdapters::Column

    def initialize(name, type, options={})
      @name = name
      @type = type
      @default = extract_default(options.fetch(:default, nil))
      @null = options.fetch(:null, false)
    end

    def type_cast(value)
      if type == :string || type == :text
        return value.to_s unless value.nil? && null
      end

      super
    end

  end

end
