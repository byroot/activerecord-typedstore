require 'active_record/typed_store/field'

module ActiveRecord::TypedStore
  class DSL
    attr_reader :fields, :coder

    def initialize(options)
      @coder = options.fetch(:coder) { default_coder }
      @fields = {}
      yield self
    end

    def default_coder
      ActiveRecord::Coders::YAMLColumn.new
    end

    def accessors
      @fields.values.select { |v| v.accessor }.map(&:name)
    end

    delegate :keys, to: :@fields

    NO_DEFAULT_GIVEN = Object.new
    [:string, :text, :integer, :float, :datetime, :date, :boolean, :decimal, :any].each do |type|
      define_method(type) do |name, **options|
        @fields[name] = Field.new(name, type, options)
      end
    end
    alias_method :date_time, :datetime
  end
end
