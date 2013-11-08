require 'active_record'
require 'json'
require 'yaml'

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
end

class CreateAllTables < ActiveRecord::Migration

  def self.recreate_table(name, *args, &block)
    execute "drop table if exists #{name}"
    create_table(name, *args, &block)
  end

  def self.up
    ActiveRecord::Base.establish_connection('test_mysql')
    recreate_table(:mysql_regular_ar_models) { |t| define_columns(t); t.text :untyped_settings }

    ActiveRecord::Base.establish_connection('test_postgresql')
    recreate_table(:postgresql_regular_ar_models) { |t| define_columns(t); t.text :untyped_settings }

    ActiveRecord::Base.establish_connection('test_sqlite3')
    recreate_table(:sqlite3_regular_ar_models) { |t| define_columns(t); t.text :untyped_settings }
    recreate_table(:yaml_typed_store_models) { |t| t.text :settings; t.text :untyped_settings }
    recreate_table(:json_typed_store_models) { |t| t.text :settings; t.text :untyped_settings }
    recreate_table(:marshal_typed_store_models) { |t| t.text :settings; t.text :untyped_settings }
  end
end
ActiveRecord::Migration.verbose = false
CreateAllTables.up

class MysqlRegularARModel < ActiveRecord::Base
  establish_connection 'test_mysql'
  store :untyped_settings, accessors: [:title]
end

class PostgresqlRegularARModel < ActiveRecord::Base
  establish_connection 'test_postgresql'
  store :untyped_settings, accessors: [:title]
end

class Sqlite3RegularARModel < ActiveRecord::Base
  establish_connection 'test_sqlite3'
  store :untyped_settings, accessors: [:title]
end

class YamlTypedStoreModel < ActiveRecord::Base
  establish_connection 'test_sqlite3'
  store :untyped_settings, accessors: [:title]
  typed_store :settings do |s|
    define_store_columns(s)
  end
end

class ColumnCoder
  
  def initialize(coder)
    @coder = coder
  end
  
  def load(data)
    return {} unless data
    @coder.load(data)
  end

  def dump(data)
    @coder.dump(data || {})
  end

end

class JsonTypedStoreModel < ActiveRecord::Base
  establish_connection 'test_sqlite3'
  store :untyped_settings, accessors: [:title]
  typed_store :settings, coder: ColumnCoder.new(JSON) do |s|
    define_store_columns(s)
  end
end

class MarshalTypedStoreModel < ActiveRecord::Base
  establish_connection 'test_sqlite3'
  store :untyped_settings, accessors: [:title]
  typed_store :settings, coder: ColumnCoder.new(Marshal) do |s|
    define_store_columns(s)
  end
end
