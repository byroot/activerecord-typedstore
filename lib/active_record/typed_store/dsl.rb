require 'active_record/typed_store/column'
module ActiveRecord::TypedStore
  class DSL
    attr_reader :columns, :coder

    def initialize(options)
      @coder = options.fetch(:coder, default_coder)
      @columns = {}
      yield self
    end

    def default_coder
      ActiveRecord::Coders::YAMLColumn.new
    end

    def accessors
      @columns.values.select { |v| v.accessor }.map(&:name)
    end

    delegate :keys, to: :@columns

    NO_DEFAULT_GIVEN = Object.new
    [:string, :text, :integer, :float, :datetime, :date, :boolean, :decimal, :any].each do |type|
      define_method(type) do |name, **options|
        if options.key?(:default)
          options[:default] = decode_default(options[:default])
        end
        @columns[name] = Column.new(name, type, options)
      end
    end
    alias_method :date_time, :datetime

    private

    def decode_default(value)
      if @coder.is_a?(ActiveRecord::Coders::YAMLColumn)
        begin
          @coder.load(value)
        rescue
          value
        end
      else
        value
      end
    end
  end
end
