require 'active_record'
require 'base64'
require 'json'
require 'yaml'

ENV["RAILS_ENV"] = "test"

ActiveRecord::Base.time_zone_aware_attributes = ENV['TIMEZONE_AWARE'] != '0'
credentials = { 'database' => 'typed_store_test', 'username' => 'typed_store', 'password' => 'typed_store' }
ActiveRecord::Base.configurations = {
  test: {
    'test_sqlite3' => { 'adapter' => 'sqlite3', 'database' => '/tmp/typed_store.db' },
  }
}

def define_columns(t, array: false)
  t.integer :no_default

  t.string :name, default: '', null: false
  t.string :email
  t.string :cell_phone, default: nil

  t.boolean :public, default: false, null: false
  t.boolean :enabled, default: true

  t.integer :age, default: 12, null: false
  t.integer :max_length

  t.float :rate, default: 0, null: false
  t.float :price

  t.date :published_on, default: '1984-06-08', null: false
  t.date :remind_on

  t.time :published_at_time, default: '1984-06-08 13:57:12', null: false
  t.time :remind_at_time

  t.datetime :published_at, default: '1984-06-08 13:57:12', null: false
  t.datetime :remind_at

  t.decimal :total_price, default: 4.2, null: false, precision: 16, scale: 2
  t.decimal :shipping_cost, precision: 16, scale: 2

  if t.is_a?(ActiveRecord::TypedStore::DSL)
    t.integer :grades, array: true
    t.string :tags, array: true, null: false, default: ['article']
    t.string :subjects, array: true, null: false, default: ['mathematics'].to_yaml

    t.string :nickname, blank: false, default: 'Please enter your nickname'
  end
end

def define_store_with_no_attributes(**options)
  typed_store :explicit_settings, accessors: false, **options do |t|
    t.string :ip_address, default: '127.0.0.1'
    t.string :user_agent
    t.any :signup, default: {}
  end
end

def define_store_with_partial_attributes(**options)
  typed_store :partial_settings, accessors: [:tax_rate], **options do |t|
    t.string :tax_rate_key
    t.string :tax_rate
  end
end

def define_store_with_attributes(**options)
  typed_store :settings, **options do |t|
    define_columns(t)
    t.any :author
    t.any :source, blank: false, default: 'web'
    t.any :signup, default: {}
    t.string :country, blank: false, default: 'Canada', accessor: false
  end
end

def define_stores_with_prefix_and_suffix(**options)
  typed_store(:prefixed_settings, prefix: true, **options) { |t| t.any :language }
  typed_store(:suffixed_settings, suffix: true, **options) { |t| t.any :language }
  typed_store(:custom_prefixed_settings, prefix: :custom, **options) { |t| t.any :language }
  typed_store(:custom_suffixed_settings, suffix: :custom, **options) { |t| t.any :language }
end

MigrationClass = ActiveRecord::Migration["#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"]
class CreateAllTables < MigrationClass
  def self.up
    ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations.configs_for(env_name: "test", name: :test_sqlite3))
    create_table(:sqlite3_regular_ar_models, force: true) { |t| define_columns(t); t.text :untyped_settings }
    create_table(:yaml_typed_store_models, force: true) { |t| %i[settings explicit_settings partial_settings untyped_settings prefixed_settings suffixed_settings custom_prefixed_settings custom_suffixed_settings].each { |column| t.text column}; t.string :regular_column }
    create_table(:json_typed_store_models, force: true) { |t| %i[settings explicit_settings partial_settings untyped_settings prefixed_settings suffixed_settings custom_prefixed_settings custom_suffixed_settings].each { |column| t.text column}; t.string :regular_column }
    create_table(:marshal_typed_store_models, force: true) { |t| %i[settings explicit_settings partial_settings untyped_settings prefixed_settings suffixed_settings custom_prefixed_settings custom_suffixed_settings].each { |column| t.text column}; t.string :regular_column }

    create_table(:dirty_tracking_models, force: true) do |t|
      t.string :title
      t.text :settings

      t.timestamps
    end
  end
end
ActiveRecord::Migration.verbose = true
ActiveRecord::Migration.suppress_messages do
  CreateAllTables.up
end

class ColumnCoder

  def initialize(coder)
    @coder = coder
  end

  def load(data)
    return {} if data.blank?
    @coder.load(data)
  end

  def dump(data)
    @coder.dump(data || {})
  end

end

class Sqlite3RegularARModel < ActiveRecord::Base
  establish_connection :test_sqlite3
  store :untyped_settings, accessors: [:title]
end

class YamlTypedStoreModel < ActiveRecord::Base
  establish_connection :test_sqlite3
  store :untyped_settings, accessors: [:title]

  after_update :read_active
  def read_active
    enabled
  end

  define_store_with_attributes
  define_store_with_no_attributes
  define_store_with_partial_attributes
  define_stores_with_prefix_and_suffix
end

class InheritedTypedStoreModel < YamlTypedStoreModel
  establish_connection :test_sqlite3

  typed_store :settings do |t|
    t.string :new_attribute
  end
end

class JsonTypedStoreModel < ActiveRecord::Base
  establish_connection :test_sqlite3
  store :untyped_settings, accessors: [:title]

  define_store_with_attributes(coder: ColumnCoder.new(JSON))
  define_store_with_no_attributes(coder: ColumnCoder.new(JSON))
  define_store_with_partial_attributes(coder: ColumnCoder.new(JSON))
  define_stores_with_prefix_and_suffix(coder: ColumnCoder.new(JSON))
end

module MarshalCoder
  extend self

  def load(serial)
    return unless serial.present?
    Marshal.load(Base64.decode64(serial))
  end

  def dump(value)
    Base64.encode64(Marshal.dump(value))
  end
end

class MarshalTypedStoreModel < ActiveRecord::Base
  establish_connection :test_sqlite3
  store :untyped_settings, accessors: [:title]

  define_store_with_attributes(coder: ColumnCoder.new(MarshalCoder))
  define_store_with_no_attributes(coder: ColumnCoder.new(MarshalCoder))
  define_store_with_partial_attributes(coder: ColumnCoder.new(MarshalCoder))
  define_stores_with_prefix_and_suffix(coder: ColumnCoder.new(MarshalCoder))
end

Models = [
  Sqlite3RegularARModel,
  YamlTypedStoreModel,
  InheritedTypedStoreModel,
  JsonTypedStoreModel,
  MarshalTypedStoreModel
]

class DirtyTrackingModel < ActiveRecord::Base
  after_update :read_active, if: -> { has_attribute?(:settings) }

  typed_store(:settings) do |f|
    f.boolean :active, default: false, null: false
  end

  def read_active
    active
  end
end
