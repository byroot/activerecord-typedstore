module ActiveRecord::TypedStore

  class DSL

    attr_reader :columns

    def initialize(accessors=true)
      @accessors = accessors
      @columns = []
      yield self
    end

    def accessors
      @columns.select(&:accessor?).map(&:name)
    end

    [:string, :integer, :float, :decimal, :datetime, :date, :boolean, :any].each do |type|
      define_method(type) do |name, options={}|
        @columns << Column.new(name, type, options.reverse_merge(accessor: @accessors))
      end
    end

  end

end
