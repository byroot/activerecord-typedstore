# ActiveRecord::TypedStore

[![Gem Version](https://badge.fury.io/rb/activerecord-typedstore.png)](http://badge.fury.io/rb/activerecord-typedstore)

[ActiveRecord::Store](http://api.rubyonrails.org/classes/ActiveRecord/Store.html) but with typed attributes.


## Installation

Add this line to your application's Gemfile:

    gem 'activerecord-typedstore'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activerecord-typedstore

## Usage

It works exactly like [ActiveRecord::Store documentation](http://api.rubyonrails.org/classes/ActiveRecord/Store.html) but you can declare the type of your attributes.

Attributes definition is similar to activerecord's migrations:

```ruby

class Shop < ActiveRecord::Base

  typed_store :settings do |s|
    s.boolean :public, default: false, null: false
    s.string :email
    s.datetime :publish_at
    s.integer :age, null: false

    # You can define array attributes like in rails 4 and postgres
    s.string :tags, array: true, default: [], null: false

    # In addition to prevent null values you can prevent blank values
    s.string :title, blank: false, default: 'Title'

    # If you don't want to enforce a datatype but still like to have default handling
    s.any :source, blank: false, default: 'web'
  end

  # You can use any ActiveModel validator
  validates :age, presence: true

end

# Values are accessible like normal model attributes
shop = Shop.new(email: 'george@cyclim.se')
shop.public?        # => false
shop.email          # => 'george@cyclim.se'
shop.published_at   # => nil

# Values are type casted
shop.update_attributes(
  age: '42',
  published_at: '1984-06-08 13:57:12'
)
shop.age                # => 42
shop.published_at.class #= DateTime

# And changes are tracked
shop.age_changed? # => false
shop.age = 12
shop.age_changed? # => true
shop.age_was      # => 42

# You can still use it as a regular store
shop.settings[:unknown] = 'Hello World'
shop.save
shop.reload
shop.settings[:unknown] # => 'Hello World'

# You can group attributes with a prefix or suffix
typed_store(:browser, prefix: true) { |s| s.string :ip } # => #browser_ip
typed_store(:browser, prefix: :web) { |s| s.string :ip } # => #web_ip
typed_store(:browser, suffix: true) { |s| s.string :ip } # => #ip_browser
typed_store(:browser, suffix: :web) { |s| s.string :ip } # => #ip_web

# If you only want type casting and default handling without accessors

# you can disable them store wide
typed_store :settings, accessors: false do |s|
  # ...
end

# or on a per attribute basis
typed_store :settings do |s|
  s.integer :age
  s.string :postal_code, accessor: false
end

```

Type casting rules and attribute behavior are exactly the same as for real database columns.
Actually the only difference is that you won't be able to query on these attributes (unless you use JSON or Postgres HStore types) and that you don't need to do a migration to add / remove an attribute.

If not, then please fill in an issue.

## Serialization methods

Just like for store, you can use any custom coder:

```ruby
module Base64MarshalCoder
  extend self

  def load(data)
    return {} unless data
    Marshal.load(Base64.decode64(data))
  end

  def dump(data)
    Base64.encode64(Marshal.dump(data || {}))
  end

end

typed_store :settings, coder: Base64MarshalCoder do |s|
  # ...
end
```

If you want to use JSON column or Postgres HStore types, then you can pass in `ActiveRecord::TypedStore::IdentityCoder` as the coder.

## HStore limitations

If you want to persist your store in a Postgres HStore, then there is some limitations imposed by the current HStore implementation in Postgres.
Since HStore can only store strings:

  - `array` attributes won't work
  - `any` attributes will be converted to string

If you use HStore because you need to be able to query the store from SQL, and any of these limitations are an issue for you,
then you could probably use the JSON column type, which do not suffer from these limitations and is also queriable. 

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
