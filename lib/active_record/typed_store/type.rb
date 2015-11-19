module ActiveRecord::TypedStore
  class Type < ActiveRecord::Type::Serialized
    def initialize(store_types, defaults)
      @store_types = store_types
      @defaults = defaults
      super(ActiveRecord::Type::Value.new, ActiveRecord::Coders::YAMLColumn.new(::Hash))
    end

    def deserialize(value)
      if value.nil?
        hash = {}
      else
        hash = super
      end
      TypedHash.new(defaults.merge(hash), store_types)
    end

    def serialize(value)
      return if value.nil?
      super(value.to_h)
    end

    def cast(value)
      value = super
      if value.is_a?(::Hash)
        TypedHash.new(defaults.merge(value), store_types)
      end
    end

    protected

    attr_reader :store_types, :defaults
  end
end
