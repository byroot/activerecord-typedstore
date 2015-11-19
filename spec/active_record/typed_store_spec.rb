require 'spec_helper'

shared_examples 'any model' do

  let(:model) { described_class.new }

  describe 'reset_column_information' do

    it 'do not definitely undefine attributes' do
      expect {
        described_class.reset_column_information
      }.to_not change { model.age_changed? }
    end

  end

  describe 'Marshal.dump' do

    it 'dumps the model' do
      Marshal.dump(model)
    end

  end

  describe 'regular AR::Store' do

    it 'save attributes as usual' do
      model.update_attributes(title: 'The Big Lebowski')
      expect(model.reload.title).to be == 'The Big Lebowski'
    end

  end

  describe 'build' do

    it 'assign attributes received by #initialize' do
      model = described_class.new(public: true)
      expect(model.public).to be true
    end

  end

  describe 'dirty tracking' do

    it 'track changed attributes' do
      expect {
        model.age = 24
      }.to change { !!model.age_changed? }.from(false).to(true)
    end

    it 'keep track of what the attribute was' do
      model.age = 24
      expect(model.age_was).to be == 12
    end

    it 'keep track of the whole changes' do
      expect {
        model.age = 24
      }.to change { model.changes['age'] }.from(nil).to([12, 24])
    end

    it 'reset recorded changes after successful save' do
      model.age = 24
      expect {
        model.save
      }.to change { !!model.age_changed? }.from(true).to(false)
    end

    if AR_VERSION >= AR_4_2
      it 'can be restored individually' do
        model.age = 24
        expect {
          model.restore_age!
        }.to change { model.age }.from(24).to(12)
      end
    else
      it 'can be reset individually' do
        model.age = 24
        expect {
          model.reset_age!
        }.to change { model.age }.from(24).to(12)
      end
    end

    it 'does not dirty track assigning the same boolean' do
      expect(model.enabled).to be true
      expect {
        model.enabled = true
      }.to_not change { model.enabled_changed? }
    end

    it 'dirty tracks when the boolean changes' do
      expect(model.enabled).to be true
      expect {
        model.enabled = false
      }.to change { !!model.enabled_changed? }.from(false).to(true)
    end

    it 'does not dirty track assigning the same boolean even if it is a string' do
      expect(model.enabled).to be true
      expect {
        model.enabled = "true"
      }.to_not change { model.enabled_changed? }
    end

    it 'dirty tracks when the string changes' do
      expect {
        model.name = "Smith"
      }.to change { !!model.name_changed? }.from(false).to(true)
    end

    it 'does not dirty track assigning the same string' do
      expect {
        model.name = ""
      }.to_not change { !!model.name_changed? }
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

    it 'default to nil if specified explicitly' do
      expect(model.cell_phone).to be_nil
    end

    it 'properly cast the value as string' do
      model.update_attributes(name: 42)
      expect(model.reload.name).to be == '42'
    end

    it 'any string is considered present' do
      model.name = 'Peter Gibbons'
      expect(model.name?).to be true
    end

    it 'empty string is not considered present' do
      expect(model.name?).to be false
    end

    it 'nil is not considered present' do
      expect(model.cell_phone?).to be false
    end

    it 'not define the attributes more than one time' do
      model.respond_to?(:foo)
      expect(described_class).to receive(:define_virtual_attribute_method).never
      model.respond_to?(:foobar)
    end
  end

  describe 'boolean attribute' do

    it 'has the defined :default as initial value' do
      expect(model.public).to be false
    end

    [true, 1, '1', 't', 'T', 'true', 'TRUE', 'on', 'ON'].each do |value|

      it "cast `#{value.inspect}` as `true`" do
        model.public = value
        expect(model.public).to be true
      end

    end

    [false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF'].each do |value|

      it "cast `#{value.inspect}` as `false`" do
        model.public = value
        expect(model.public).to be false
      end

    end

    it 'properly persit the value' do
      model.update_attributes(public: false)
      expect(model.reload.public).to be false
      model.update_attributes(public: true)
      expect(model.reload.public).to be true
    end

    it 'initialize with default value if the column is not nullable' do
      expect(model.public).to be false
      model.save
      expect(model.reload.public).to be false
    end

    it 'can store nil if the column is nullable' do
      model.update_attributes(enabled: nil)
      expect(model.reload.enabled).to be_nil
    end

    it 'save the default value if the column is nullable but the value not explictly set' do
      model.save
      expect(model.reload.enabled).to be true
    end

    it 'true is considered present' do
      expect(model.enabled?).to be true
    end

    it 'false is not considered present' do
      expect(model.public?).to be false
    end

    it 'nil is not considered present' do
      model.update_attributes(enabled: nil)
      expect(model.enabled?).to be false
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

    it 'positive values are considered present' do
      expect(model.age?).to be true
    end

    it 'negative values are considered present' do
      model.age = -42
      expect(model.age?).to be true
    end

    it '0 is not considered present' do
      model.age = 0
      expect(model.age?).to be false
    end

    it 'nil is not considered present' do
      model.max_length = nil
      expect(model.max_length?).to be false
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

    it 'positive values are considered present' do
      model.rate = 4.2
      expect(model.rate?).to be true
    end

    it 'negative values are considered present' do
      model.rate = -4.2
      expect(model.rate?).to be true
    end

    it '0 is not considered present' do
      expect(model.rate?).to be false
    end

    it 'nil is not considered present' do
      expect(model.price?).to be false
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

    it 'positive values are considered present' do
      model.shipping_cost = BigDecimal.new('4.2')
      expect(model.shipping_cost?).to be true
    end

    it 'negative values are considered present' do
      model.shipping_cost = BigDecimal.new('-4.2')
      expect(model.shipping_cost?).to be true
    end

    it '0 is not considered present' do
      model.shipping_cost = BigDecimal.new('0')
      expect(model.shipping_cost?).to be false
    end

    it 'nil is not considered present' do
      expect(model.shipping_cost?).to be false
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

    it 'any non-nil value is considered present' do
      model.remind_on = Date.new
      expect(model.remind_on?).to be true
    end

    it 'nil is not considered present' do
      expect(model.remind_on?).to be false
    end

  end

  describe 'datetime attributes' do

    let(:datetime) { DateTime.new(1984, 6, 8, 13, 57, 12) }
    let(:datetime_string) { '1984-06-08 13:57:12' }
    let(:time) { datetime_string.respond_to?(:in_time_zone) ? datetime_string.in_time_zone : Time.parse(datetime_string) }

    context "with ActiveRecord #{ActiveRecord::VERSION::STRING}" do

      if AR_VERSION < AR_4_0

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

        if ActiveRecord::Base.time_zone_aware_attributes

          it 'properly cast assigned value to time' do
            model.remind_at = datetime_string
            expect(model.remind_at).to be == time
          end

        else

          it 'properly cast assigned value to datetime' do
            model.remind_at = datetime_string
            expect(model.remind_at).to be == datetime
          end

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

    it 'any non-nil value is considered present' do
      model.remind_at = DateTime.new
      expect(model.remind_at?).to be true
    end

    it 'nil is not considered present' do
      expect(model.remind_at?).to be false
    end

  end

end

shared_examples 'a store' do |retain_type=true|

  let(:model) { described_class.new }

  describe 'assigning the store' do

    it 'coerce it to the proper typed hash' do
      expect {
        model.settings = {}
      }.to_not change { model.settings.class }
    end

    it 'still handle default values' do
      expect {
        model.settings = {}
      }.to_not change { model.settings['nickname'] }
    end

  end

  describe 'attributes' do

    it 'retrieve default if assigned nil and null not allowed' do
      model.update_attributes(age: nil)
      expect(model.age).to be == 12
    end

    context 'when column cannot be blank' do

      it 'retreive default if not persisted yet, and nothing was assigned' do
        expect(model.nickname).to be == 'Please enter your nickname'
      end

      it 'retreive default if assigned a blank value' do
        model.update_attributes(nickname: '')
        expect(model.nickname).to be == 'Please enter your nickname'
        expect(model.reload.nickname).to be == 'Please enter your nickname'
      end

    end

    it 'do not respond to <attribute>_before_type_cast' do
      expect(model).to_not respond_to :nickname_before_type_cast
    end

  end

  describe 'attributes without accessors' do

    it 'cannot be accessed as a model attribute' do
      expect(model).to_not respond_to :country
      expect(model).to_not respond_to :country=
    end

    it 'cannot be queried' do
      expect(model).to_not respond_to :country?
    end

    it 'cannot be reset' do
      expect(model).to_not respond_to :reset_country!
    end

    it 'still has casting a default handling' do
      expect(model.settings[:country]).to be == 'Canada'
    end

  end

  describe '`any` attributes' do

    it 'accept any type' do
      model.update_attributes(author: 'George')
      expect(model.reload.author).to be == 'George'

      model.update_attributes(author: 42)
      expect(model.reload.author).to be == (retain_type ? 42 : '42')
    end

    it 'still handle default' do
      model.update_attributes(source: '')
      expect(model.reload.source).to be == 'web'
    end

  end

  describe 'updated defaults' do

    it 'update defaults for outdated serials' do
      model.save!
      expect(model.settings[:brand_new]).to be_nil
      new_column = ActiveRecord::TypedStore::Column.new(:brand_new, :boolean, null: false, default: true)
      begin
        model.class::SettingsHash.columns['brand_new'] = new_column
        model.reload
        expect(model.settings[:brand_new]).to be true
      ensure
        model.class::SettingsHash.columns.delete('brand_new')
      end
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

  describe "#write_attribute" do

    it "attr_name can be a string" do
      value = 12
      model.send(:write_attribute, 'age', value)
      expect(model.age).to be == value
    end

    it "attr_name can be a symbol" do
      value = 12
      model.send(:write_attribute, :age, value)
      expect(model.age).to be == value
    end

  end

end

shared_examples 'a model supporting arrays' do |pg_native=false|

  let(:model) { described_class.new }

  it 'retrieve an array of values' do
    model.update_attributes(grades: [1, 2, 3, 4])
    expect(model.reload.grades).to be == [1, 2, 3, 4]
  end

  it 'cast values inside the array (integer)' do
    pending('ActiveRecord bug: https://github.com/rails/rails/pull/11245') if pg_native && AR_VERSION < AR_4_2
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

  if !pg_native || AR_VERSION < AR_4_2
    it 'convert non array value as empty array' do
      model.update_attributes(grades: 'foo')
      expect(model.reload.grades).to be == []
    end
  end

  if !pg_native || AR_VERSION >= AR_4_1
    it 'accept multidimensianl arrays' do
      model.update_attributes(grades: [[1, 2], [3, 4]])
      expect(model.reload.grades).to be == [[1, 2], [3, 4]]
    end
  end

  if pg_native

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
  it_should_behave_like 'any model'
  it_should_behave_like 'a db backed model'
end

describe MysqlRegularARModel do
  it_should_behave_like 'any model'
  it_should_behave_like 'a db backed model'
end if defined?(MysqlRegularARModel)

describe PostgresqlRegularARModel do
  it_should_behave_like 'any model'
  it_should_behave_like 'a db backed model'
  it_should_behave_like 'a model supporting arrays', true if AR_VERSION >= AR_4_0
end if defined?(PostgresqlRegularARModel)

describe PostgresHstoreTypedStoreModel do
  if AR_VERSION >= AR_4_1
    pending('TODO: Rails edge HStore compatibiliy')
  else
    it_should_behave_like 'any model'
    it_should_behave_like 'a store', false
  end
end if defined?(PostgresHstoreTypedStoreModel)

describe PostgresJsonTypedStoreModel do
  it_should_behave_like 'any model'
  it_should_behave_like 'a store'
  it_should_behave_like 'a model supporting arrays'
end if defined?(PostgresJsonTypedStoreModel)

describe YamlTypedStoreModel do
  it_should_behave_like 'any model'
  it_should_behave_like 'a store'
  it_should_behave_like 'a model supporting arrays'
end

# describe JsonTypedStoreModel do
#   it_should_behave_like 'any model'
#   it_should_behave_like 'a store'
#   it_should_behave_like 'a model supporting arrays'
# end

# describe MarshalTypedStoreModel do
#   it_should_behave_like 'any model'
#   it_should_behave_like 'a store'
#   it_should_behave_like 'a model supporting arrays'
# end
