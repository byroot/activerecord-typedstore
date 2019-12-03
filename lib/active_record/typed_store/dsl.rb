# frozen_string_literal: true

require 'active_record/typed_store/field'

module ActiveRecord::TypedStore
  class DSL
    attr_reader :fields, :coder

    def initialize(attribute_name, options)
      @coder = options.fetch(:coder) { default_coder(attribute_name) }
      @accessors = options[:accessors]
      @accessors = [] if options[:accessors] == false
      @fields = {}
      yield self
    end

    if ActiveRecord.gem_version < Gem::Version.new('5.1.0')
      def default_coder(attribute_name)
        ActiveRecord::Coders::YAMLColumn.new
      end
    else
      def default_coder(attribute_name)
        ActiveRecord::Coders::YAMLColumn.new(attribute_name)
      end
    end

    def accessors
      @accessors || @fields.values.select(&:accessor).map(&:name)
    end

    delegate :keys, to: :@fields

    NO_DEFAULT_GIVEN = Object.new
    [:string, :text, :integer, :float, :time, :datetime, :date, :boolean, :decimal, :any].each do |type|
      define_method(type) do |name, **options|
        @fields[name] = Field.new(name, type, options)
      end
    end
    alias_method :date_time, :datetime
  end
end
