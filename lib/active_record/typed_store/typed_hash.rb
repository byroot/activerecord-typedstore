module ActiveRecord::TypedStore

  class TypedHash < HashWithIndifferentAccess

    class << self

      attr_reader :columns

      def create(columns)
        Class.new(self) do
          @columns = columns.index_by { |c| c.name.to_s }
        end
      end

    end

    def initialize(constructor={})
      super()
      update(defaults_hash)
      update(constructor) if constructor.is_a?(Hash)
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

    delegate :columns, to: 'self.class'

    def defaults_hash
      Hash[self.class.columns.values.select(&:has_default?).map { |c| [c.name, c.default] }]
    end

    def cast_value(key, value)
      key = convert_key(key)
      column = columns[key]
      return value unless column

      casted_value = column.cast(value)

      if casted_value.nil? && !column.null && column.has_default?
        return column.default
      end

      casted_value
    end

  end

end
