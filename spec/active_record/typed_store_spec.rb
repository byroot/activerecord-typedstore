require 'spec_helper'

ar_version = Gem::Version.new(ActiveRecord::VERSION::STRING)
ar_4_0 = Gem::Version.new('4.0')
ar_4_1 = Gem::Version.new('4.1.0.beta')

shared_examples 'any model' do

  let(:model) { described_class.new }

  describe 'regular AR::Store' do

    it 'save attributes as usual' do
      model.update_attributes(title: 'The Big Lebowski')
      expect(model.reload.title).to be == 'The Big Lebowski'
    end

  end

  describe 'build' do

    it 'assign attributes received by #initialize' do
      model = described_class.new(public: true)
      expect(model.public).to be_true
    end

  end

  describe 'unknown attribute' do

    it 'raise an ActiveRecord::UnknownAttributeError on save attemps' do
      expect {
        model.update_attributes(unknown_attribute: 42)
      }.to raise_error ActiveRecord::UnknownAttributeError
    end

    it 'raise a NoMethodError on assignation attemps' do
      expect {
        model.unknown_attribute = 42
      }.to raise_error NoMethodError
    end

  end

  describe 'all attributes' do

    it 'is initialized at nil if :default is not defined' do
      expect(model.no_default).to be_nil
    end

  end

  describe 'string attribute' do

    it 'has the defined default as initial value' do
      expect(model.name).to be == ''
    end

    it 'properly cast the value as string' do
      model.update_attributes(name: 42)
      expect(model.reload.name).to be == '42'
    end

  end

  describe 'boolean attribute' do

    it 'has the defined :default as initial value' do
      expect(model.public).to be_false
    end

    [true, 1, '1', 't', 'T', 'true', 'TRUE', 'on', 'ON'].each do |value|

      it "cast `#{value.inspect}` as `true`" do
        model.public = value
        expect(model.public).to be_true
      end

    end

    [false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF'].each do |value|

      it "cast `#{value.inspect}` as `false`" do
        model.public = value
        expect(model.public).to be_false
      end

    end

    it 'properly persit the value' do
      model.update_attributes(public: false)
      expect(model.reload.public).to be_false
      model.update_attributes(public: true)
      expect(model.reload.public).to be_true
    end

    it 'initialize with default value if the column is not nullable' do
      expect(model.public).to be_false
      model.save
      expect(model.reload.public).to be_false
    end

    it 'can store nil if the column is nullable' do
      model.update_attributes(enabled: nil)
      expect(model.reload.enabled).to be_nil
    end

    it 'save the default value if the column is nullable but the value not explictly set' do
      model.save
      expect(model.reload.enabled).to be_true
    end

  end

  describe 'integer attributes' do

    it 'has the defined default as initial value' do
      expect(model.age).to be == 12
    end

    it 'properly cast assigned value to integer' do
      model.age = '42'
      expect(model.age).to be == 42
    end

    it 'properly cast non numeric values to integer' do
      model.age = 'foo'
      expect(model.age).to be == 0
    end

    it 'can store nil if the column is nullable' do
      model.update_attributes(max_length: nil)
      expect(model.reload.max_length).to be_nil
    end

  end

  describe 'float attributes' do

    it 'has the defined default as initial value' do
      expect(model.rate).to be_zero
    end

    it 'properly cast assigned value to float' do
      model.rate = '4.2'
      expect(model.rate).to be == 4.2
    end

    it 'properly cast non numeric values to float' do
      model.rate = 'foo'
      expect(model.rate).to be == 0
    end

    it 'can store nil if the column is nullable' do
      model.update_attributes(price: nil)
      expect(model.reload.price).to be_nil
    end

  end

  describe 'decimal attributes' do

    it 'has the defined default as initial value' do
      expect(model.total_price).to be == BigDecimal.new('4.2')
      expect(model.total_price).to be_a BigDecimal
    end

    it 'properly cast assigned value to decimal' do
      model.shipping_cost = 4.2
      expect(model.shipping_cost).to be == BigDecimal.new('4.2')
      expect(model.shipping_cost).to be_a BigDecimal
    end

    it 'properly cast non numeric values to decimal' do
      model.total_price = 'foo'
      expect(model.total_price).to be == 0
      expect(model.total_price).to be_a BigDecimal
    end

    it 'retreive a BigDecimal instance' do
      model.update_attributes(shipping_cost: 4.2)
      expect(model.reload.shipping_cost).to be == BigDecimal.new('4.2')
      expect(model.reload.shipping_cost).to be_a BigDecimal
    end

    it 'can store nil if the column is nullable' do
      model.update_attributes(shipping_cost: nil)
      expect(model.reload.shipping_cost).to be_nil
    end

  end

  describe 'date attributes' do

    let(:date) { Date.new(1984, 6, 8) }

    it 'has the defined default as initial value' do
      expect(model.published_on).to be == date
    end

    it 'properly cast assigned value to date' do
      model.remind_on = '1984-06-08'
      expect(model.remind_on).to be == date
    end

    it 'retreive a Date instance' do
      model.update_attributes(published_on: date)
      expect(model.reload.published_on).to be == date
    end

    it 'nillify unparsable dates' do
      model.update_attributes(remind_on: 'foo')
      expect(model.remind_on).to be_nil
    end

    it 'can store nil if the column is nullable' do
      model.update_attributes(remind_on: nil)
      expect(model.reload.remind_on).to be_nil
    end

  end

  describe 'datetime attributes' do

    let(:datetime) { DateTime.new(1984, 6, 8, 13, 57, 12) }
    let(:datetime_string) { '1984-06-08 13:57:12' }
    let(:time) { Time.parse(datetime_string) }

    context "with ActiveRecord #{ActiveRecord::VERSION::STRING}" do

      if ar_version < ar_4_0

        it 'has the defined default as initial value' do
          model.save
          expect(model.published_at).to be == time
        end

        it 'properly cast assigned value to time' do
          model.remind_at = datetime_string
          expect(model.remind_at).to be == time
        end

        it 'properly cast assigned value to time on save' do
          model.remind_at = datetime_string
          model.save
          model.reload
          expect(model.remind_at).to be == time
        end

        it 'retreive a Time instance' do
          model.update_attributes(published_at: datetime)
          expect(model.reload.published_at).to be == time
        end

      else

        it 'has the defined default as initial value' do
          model.save
          expect(model.reload.published_at).to be == datetime
        end

        it 'retreive a DateTime instance' do
          model.update_attributes(published_at: datetime)
          expect(model.reload.published_at).to be == datetime
        end

        it 'properly cast assigned value to datetime' do
          model.remind_at = datetime_string
          expect(model.remind_at).to be == datetime
        end
      end

    end

    it 'nillify unparsable datetimes' do
      model.update_attributes(remind_at: 'foo')
      expect(model.remind_at).to be_nil
    end

    it 'can store nil if the column is nullable' do
      model.update_attributes(remind_at: nil)
      expect(model.reload.remind_at).to be_nil
    end

  end

end

shared_examples 'a store' do

  let(:model) { described_class.new }

  describe 'attributes' do

    it 'retrieve default if assigned nil and null not allowed' do
      model.update_attributes(age: nil)
      expect(model.age).to be == 12
    end

    it 'retreive default if assigned a blank value and column cannot be blank' do
      model.update_attributes(nickname: '')
      expect(model.reload.nickname).to be == 'Please enter your nickname'
    end

  end

end

shared_examples 'a db backed model' do

  let(:model) { described_class.new }

  it 'let the underlying db raise if assigned nil on non nullable column' do
    expect {
      model.update_attributes(age: nil)
    }.to raise_error(ActiveRecord::StatementInvalid)
  end

end

shared_examples 'a model supporting arrays' do |regular=false|

  let(:model) { described_class.new }

  it 'retrieve an array of values' do
    model.update_attributes(grades: [1, 2, 3, 4])
    expect(model.reload.grades).to be == [1, 2, 3, 4]
  end

  it 'cast values inside the array (integer)' do
    pending('ActiveRecord bug: https://github.com/rails/rails/pull/11245') if regular
    model.update_attributes(grades: ['1', 2, 3.4])
    expect(model.reload.grades).to be == [1, 2, 3]
  end

  it 'cast values inside the array (string)' do
    model.update_attributes(tags: [1, 2.3])
    expect(model.reload.tags).to be == %w(1 2.3)
  end

  it 'accept nil inside array even if collumn is non nullable' do
    model.update_attributes(tags: [1, nil])
    expect(model.reload.tags).to be == ['1', nil]
  end

  it 'convert non array value as empty array' do
    model.update_attributes(grades: 'foo')
    expect(model.reload.grades).to be == []
  end

  if !regular || ar_version == ar_4_1
    it 'accept multidimensianl arrays' do
      model.update_attributes(grades: [[1, 2], [3, 4]])
      expect(model.reload.grades).to be == [[1, 2], [3, 4]]
    end
  end

  if regular

    it 'raise on non rectangular multidimensianl arrays' do
      expect{
        model.update_attributes(grades: [[1, 2], [3, 4, 5]])
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it 'raise on non nil assignation if column is non nullable' do
      expect{
        model.update_attributes(tags: nil)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

  else

    it 'accept non rectangular multidimensianl arrays' do
      model.update_attributes(grades: [[1, 2], [3, 4, 5]])
      expect(model.reload.grades).to be == [[1, 2], [3, 4, 5]]
    end

    it 'retreive default if assigned null' do
      model.update_attributes(tags: nil)
      expect(model.reload.tags).to be == []
    end

  end

end

describe Sqlite3RegularARModel do
  ActiveRecord::Base.establish_connection('test_sqlite3')
  it_should_behave_like 'any model'
  it_should_behave_like 'a db backed model'
end

describe MysqlRegularARModel do
  it_should_behave_like 'any model'
  it_should_behave_like 'a db backed model'
end

describe PostgresqlRegularARModel do
  it_should_behave_like 'any model'
  it_should_behave_like 'a db backed model'
  it_should_behave_like 'a model supporting arrays', true if ar_version >= ar_4_0
end

describe YamlTypedStoreModel do
  it_should_behave_like 'any model'
  it_should_behave_like 'a store'
  it_should_behave_like 'a model supporting arrays'
end

describe JsonTypedStoreModel do
  it_should_behave_like 'any model'
  it_should_behave_like 'a store'
  it_should_behave_like 'a model supporting arrays'
end

describe MarshalTypedStoreModel do
  it_should_behave_like 'any model'
  it_should_behave_like 'a store'
  it_should_behave_like 'a model supporting arrays'
end
