require 'spec_helper'

shared_examples 'a model' do

  let(:model) { described_class.new }

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
      expect(model.age).to be_zero
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
      model.published_on = 'foo'
      expect(model.published_on).to be_nil
    end

    it 'can store nil if the column is nullable' do
      model.update_attributes(remind_on: nil)
      expect(model.reload.remind_on).to be_nil
    end

  end

  describe 'datetime attributes' do

    let(:datetime) { DateTime.new(1984, 6, 8, 13, 57, 12) }

    it 'has the defined default as initial value' do
      model.save
      expect(model.published_at).to be == datetime
    end

    it 'properly cast assigned value to datetime' do
      model.remind_at = '1984-06-08 13:57:12'
      expect(model.remind_at).to be == datetime
    end

    it 'retreive a DateTime instance' do
      model.update_attributes(published_at: datetime)
      expect(model.reload.published_at).to be == datetime
    end

    it 'nillify unparsable datetimes' do
      model.published_at = 'foo'
      expect(model.published_at).to be_nil
    end

    it 'can store nil if the column is nullable' do
      model.update_attributes(remind_at: nil)
      expect(model.reload.remind_at).to be_nil
    end

  end

end

describe RegularARModel do
  it_should_behave_like 'a model'
end

describe YamlTypedStoreModel do
  it_should_behave_like 'a model'
end

describe JsonTypedStoreModel do
  it_should_behave_like 'a model'
end

describe MarshalTypedStoreModel do
  it_should_behave_like 'a model'
end
