require 'active_record/typed_store/dsl'
require 'active_record/typed_store/type'
require 'active_record/typed_store/typed_hash'

module ActiveRecord::TypedStore
  module Extension
    extend ActiveSupport::Concern

    module ClassMethods
      def typed_store(store_attribute, options={}, &block)
        dsl = DSL.new(options, &block)
        attribute(store_attribute, Type.new(dsl.types, dsl.defaults))
        store_accessor(store_attribute, dsl.accessors)

        dsl.accessors.each do |accessor_name|
          define_method("#{accessor_name}_changed?") do
            send("#{store_attribute}_changed?") &&
              send(store_attribute)[accessor_name] != send("#{store_attribute}_was")[accessor_name]
          end

          define_method("#{accessor_name}?") do
            send(accessor_name).present?
          end
        end
      end
    end
  end
end
