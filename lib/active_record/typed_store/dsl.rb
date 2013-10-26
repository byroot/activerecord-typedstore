module ActiveRecord::TypedStore

  class DSL

    attr_reader :columns

    def initialize
      @columns = []
      yield self
    end

    def column_names
      @columns.map(&:name)
    end

    [:string, :integer, :float, :decimal, :datetime, :date, :boolean].each do |type|
      define_method(type) do |name, options={}|
        @columns << Column.new(name, type, options)
      end
    end

  end

end
