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

    [:string, :text, :integer, :float, :datetime, :date, :boolean, :any].each do |type|
      define_method(type) do |name, options = {}|
        @columns << Column.new(name, type, {accessor: @accessors}.merge(options))
      end
    end

    def decimal(name, options = {})
      @columns << Column.new(name, :decimal, {accessor: @accessors, limit: 20, scale: 6}.merge(options))
    end

  end

end
