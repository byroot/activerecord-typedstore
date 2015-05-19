require 'active_record'
require 'json'
require 'yaml'

ActiveRecord::Base.time_zone_aware_attributes = ENV['TIMEZONE_AWARE'] != '0'
ActiveRecord::Base.configurations = {
  'test_sqlite3' => {adapter: 'sqlite3', database: "/tmp/typed_store.db"},
  'test_postgresql' => {adapter: 'postgresql', database: 'typed_store_test', username: 'postgres'},
  'test_mysql' => {adapter: 'mysql2', database: 'typed_store_test', username: 'travis'},
}

def define_columns(t)
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

  t.datetime :published_at, default: '1984-06-08 13:57:12', null: false
  t.datetime :remind_at

  t.decimal :total_price, default: 4.2, null: false, precision: 16, scale: 2
  t.decimal :shipping_cost, precision: 16, scale: 2

  t.integer :grades, array: true
  t.string :tags, array: true, null: false, default: []

  t.string :nickname, blank: false, default: 'Please enter your nickname'
end

def define_store_columns(t)
  define_columns(t)
  t.any :author
  t.any :source, blank: false, default: 'web'
  t.string :country, blank: false, default: 'Canada', accessor: false
end

class CreateAllTables < ActiveRecord::Migration

  def self.recreate_table(name, *args, &block)
    execute "drop table if exists #{name}"
    create_table(name, *args, &block)
  end

  def self.up
    if ENV['MYSQL']
      ActiveRecord::Base.establish_connection(:test_mysql)
      recreate_table(:mysql_regular_ar_models) { |t| define_columns(t); t.text :untyped_settings }
    end

    if ENV['POSTGRES']
      ActiveRecord::Base.establish_connection(ENV['POSTGRES_URL'] || :test_postgresql)
      recreate_table(:postgresql_regular_ar_models) { |t| define_columns(t); t.text :untyped_settings }

      execute "create extension if not exists hstore"
      recreate_table(:postgres_hstore_typed_store_models) { |t| t.hstore :settings; t.text :untyped_settings }

      if ENV['POSTGRES_JSON']
        execute "create extension if not exists json"
        recreate_table(:postgres_json_typed_store_models) { |t| t.json :settings; t.text :untyped_settings }
      end
    end

    ActiveRecord::Base.establish_connection(:test_sqlite3)
    recreate_table(:sqlite3_regular_ar_models) { |t| define_columns(t); t.text :untyped_settings }
    recreate_table(:yaml_typed_store_models) { |t| t.text :settings; t.text :untyped_settings }
    recreate_table(:json_typed_store_models) { |t| t.text :settings; t.text :untyped_settings }
    recreate_table(:marshal_typed_store_models) { |t| t.text :settings; t.text :untyped_settings }
  end
end
ActiveRecord::Migration.verbose = true
CreateAllTables.up

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

module AsJson
  extend self

  def load(value)
    value
  end

  def dump(value)
    value.as_json
  end

end

if ENV['MYSQL']
  class MysqlRegularARModel < ActiveRecord::Base
    establish_connection :test_mysql
    store :untyped_settings, accessors: [:title]
  end
end

if ENV['POSTGRES']
  class PostgresqlRegularARModel < ActiveRecord::Base
    establish_connection ENV['POSTGRES_URL'] || :test_postgresql
    store :untyped_settings, accessors: [:title]
  end


  class PostgresHstoreTypedStoreModel < ActiveRecord::Base
    establish_connection ENV['POSTGRES_URL'] || :test_postgresql
    store :untyped_settings, accessors: [:title]
    typed_store :settings, coder: ColumnCoder.new(AsJson) do |s|
      define_store_columns(s)
    end
  end

  if ENV['POSTGRES_JSON']
    class PostgresJsonTypedStoreModel < ActiveRecord::Base
      establish_connection ENV['POSTGRES_URL'] || :test_postgresql
      store :untyped_settings, accessors: [:title]
      typed_store :settings, coder: ColumnCoder.new(AsJson) do |s|
        define_store_columns(s)
      end
    end
  end
end

class Sqlite3RegularARModel < ActiveRecord::Base
  establish_connection :test_sqlite3
  store :untyped_settings, accessors: [:title]
end

class YamlTypedStoreModel < ActiveRecord::Base
  establish_connection :test_sqlite3
  store :untyped_settings, accessors: [:title]
  typed_store :settings do |s|
    define_store_columns(s)
  end
end

class JsonTypedStoreModel < ActiveRecord::Base
  establish_connection :test_sqlite3
  store :untyped_settings, accessors: [:title]
  typed_store :settings, coder: ColumnCoder.new(JSON) do |s|
    define_store_columns(s)
  end
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
  typed_store :settings, coder: ColumnCoder.new(MarshalCoder) do |s|
    define_store_columns(s)
  end
end


Models = [
  Sqlite3RegularARModel,
  YamlTypedStoreModel,
  JsonTypedStoreModel,
  MarshalTypedStoreModel
]
Models << MysqlRegularARModel if defined?(MysqlRegularARModel)
Models << PostgresqlRegularARModel if defined?(PostgresqlRegularARModel)
Models << PostgresHstoreTypedStoreModel if defined?(PostgresHstoreTypedStoreModel)
Models << PostgresJsonTypedStoreModel if defined?(PostgresJsonTypedStoreModel)
