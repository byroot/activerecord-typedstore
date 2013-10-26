require 'active_record'

ActiveRecord::Base.configurations = {'test' => {:adapter => 'sqlite3', :database => ':memory:'}}
ActiveRecord::Base.establish_connection('test')

def define_columns(t)
  t.integer :no_default

  t.string :name, default: ''
  t.string :email, null: true

  t.boolean :public, default: false
  t.boolean :enabled, default: true, null: true

  t.integer :age, default: 0
  t.integer :max_length, null: true

  t.float :rate, default: 0
  t.float :price, null: true

  t.date :published_on, default: '1984-06-08'
  t.date :remind_on, null: true

  t.datetime :published_at, default: '1984-06-08 13:57:12'
  t.datetime :remind_at, null: true

  t.decimal :total_price, default: 4.2
  t.decimal :shipping_cost, null: true

end

class CreateAllTables < ActiveRecord::Migration
  def self.up
    create_table :regular_ar_models do |t|
      define_columns(t)
    end

    create_table :typed_store_models do |t|
      t.text :settings
    end
  end
end
ActiveRecord::Migration.verbose = false
CreateAllTables.up

class RegularARModel < ActiveRecord::Base
end

class TypedStoreModel < ActiveRecord::Base
  typed_store :settings do |s|
    define_columns(s)
  end
end
