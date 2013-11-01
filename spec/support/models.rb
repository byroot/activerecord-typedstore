require 'active_record'
require 'json'
require 'yaml'

ActiveRecord::Base.configurations = {'test' => {:adapter => 'sqlite3', :database => ':memory:'}}
ActiveRecord::Base.establish_connection('test')

def define_columns(t)
  t.integer :no_default

  t.string :name, default: '', null: false
  t.string :email, null: true

  t.boolean :public, default: false, null: false
  t.boolean :enabled, default: true, null: true

  t.integer :age, default: 12, null: false
  t.integer :max_length, null: true

  t.float :rate, default: 0, null: false
  t.float :price, null: true

  t.date :published_on, default: '1984-06-08', null: false
  t.date :remind_on, null: true

  t.datetime :published_at, default: '1984-06-08 13:57:12', null: false
  t.datetime :remind_at, null: true

  t.decimal :total_price, default: 4.2, null: false
  t.decimal :shipping_cost, null: true

end

class CreateAllTables < ActiveRecord::Migration
  def self.up
    create_table(:regular_ar_models) { |t| define_columns(t) }
    create_table(:yaml_typed_store_models) { |t| t.text :settings }
    create_table(:json_typed_store_models) { |t| t.text :settings }
    create_table(:marshal_typed_store_models) { |t| t.text :settings }
  end
end
ActiveRecord::Migration.verbose = false
CreateAllTables.up

class RegularARModel < ActiveRecord::Base
end

class YamlTypedStoreModel < ActiveRecord::Base
  typed_store :settings do |s|
    define_columns(s)
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
  typed_store :settings, coder: ColumnCoder.new(JSON) do |s|
    define_columns(s)
  end
end

class MarshalTypedStoreModel < ActiveRecord::Base
  typed_store :settings, coder: ColumnCoder.new(Marshal) do |s|
    define_columns(s)
  end
end
