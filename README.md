# ActiveRecord::TypedStore

[![Build Status](https://secure.travis-ci.org/byroot/activerecord-typedstore.png)](http://travis-ci.org/byroot/activerecord-typedstore)
[![Code Climate](https://codeclimate.com/github/byroot/activerecord-typedstore.png)](https://codeclimate.com/github/byroot/activerecord-typedstore)
[![Coverage Status](https://coveralls.io/repos/byroot/activerecord-typedstore/badge.png)](https://coveralls.io/r/byroot/activerecord-typedstore)

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
    s.boolean :public, default: false
    s.string :email, null: true
    s.datetime :publish_at, null: true
    s.integer :age
    
    # You can define array attributes like in rails 4 and postgres
    s.string :tags, array: true, default: [], null: false
  end

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

# You can still use it as a regular store
shop.settings[:unknown] = 'Hello World'
shop.save
shop.reload
shop.settings[:unknown] # => 'Hello World'

```

Type casting rules and attribute behavior are exactly the same as a for real database columns.
Actually the only difference is that you wont be able to query on these attributes (unless you use Postgres JSON or HStore types) and that you don't need to do a migration to add / remove an attribute.

If not, please fill an issue.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
