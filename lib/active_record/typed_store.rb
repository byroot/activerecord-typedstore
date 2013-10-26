require 'active_support'

module ActiveRecord
  module TypedStore
  end
end

ActiveSupport.on_load(:active_record) do
  require 'active_record/typed_store/extension'
  ::ActiveRecord::Base.send :include, ActiveRecord::TypedStore::Extension
end
