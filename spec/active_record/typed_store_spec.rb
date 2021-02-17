require 'spec_helper'

shared_examples 'any model' do

  let(:model) { described_class.new }

  describe 'reset_column_information' do

    it 'do not definitely undefine attributes' do
      expect(model.age).to be_present
      expect(model.age_changed?).to be_falsey

      described_class.reset_column_information

      model = described_class.new
      expect(model.age).to be_present
      expect(model.age_changed?).to be_falsey
    end

  end

  describe 'Marshal.dump' do

    it 'dumps the model' do
      Marshal.dump(model)
    end

  end

  describe 'regular AR::Store' do

    it 'save attributes as usual' do
      model.update(title: 'The Big Lebowski')
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
      expect(model.age_changed?).to be_falsey
      model.age = 24
      expect(model.age_changed?).to be_truthy
    end

    it 'keep track of what the attribute was' do
      model.age = 24
      expect(model.age_was).to eq 12
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

    it 'can be restored individually' do
      model.age = 24
      expect {
        model.restore_age!
      }.to change { model.age }.from(24).to(12)
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
        model.update(unknown_attribute: 42)
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

    it 'is accessible throught #read_attribute' do
      model.name = 'foo'
      expect(model.read_attribute(:name)).to be == 'foo'
    end

    it 'is accessible through #read_attribute when attribute is nil' do
      expect(model.read_attribute(nil)).to be_nil
    end

    it 'allows #increment! when attribute is nil' do
      expect { model.increment!(nil) }.to raise_error(ActiveModel::MissingAttributeError)
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
      model.update(name: 42)
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
        expect(model.public?).to be false
      end

    end

    it 'properly persit the value' do
      model.update(public: false)
      expect(model.reload.public).to be false
      model.update(public: true)
      expect(model.reload.public).to be true
    end

    it 'initialize with default value if the column is not nullable' do
      expect(model.public).to be false
      model.save
      expect(model.reload.public).to be false
    end

    it 'can store nil if the column is nullable' do
      model.update(enabled: nil)
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
      model.update(enabled: nil)
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
      model.update(max_length: nil)
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
      model.update(price: nil)
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
      expect(model.total_price).to be == BigDecimal('4.2')
      expect(model.total_price).to be_a BigDecimal
    end

    it 'properly cast assigned value to decimal' do
      model.shipping_cost = 4.2
      expect(model.shipping_cost).to be == BigDecimal('4.2')
      expect(model.shipping_cost).to be_a BigDecimal
    end

    it 'properly cast non numeric values to decimal' do
      model.total_price = 'foo'
      expect(model.total_price).to be == 0
      expect(model.total_price).to be_a BigDecimal
    end

    it 'retreive a BigDecimal instance' do
      model.update(shipping_cost: 4.2)
      expect(model.reload.shipping_cost).to be == BigDecimal('4.2')
      expect(model.reload.shipping_cost).to be_a BigDecimal
    end

    it 'can store nil if the column is nullable' do
      model.update(shipping_cost: nil)
      expect(model.reload.shipping_cost).to be_nil
    end

    it 'positive values are considered present' do
      model.shipping_cost = BigDecimal('4.2')
      expect(model.shipping_cost?).to be true
    end

    it 'negative values are considered present' do
      model.shipping_cost = BigDecimal('-4.2')
      expect(model.shipping_cost?).to be true
    end

    it '0 is not considered present' do
      model.shipping_cost = BigDecimal('0')
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
      model.update(published_on: date)
      expect(model.reload.published_on).to be == date
    end

    it 'nillify unparsable dates' do
      model.update(remind_on: 'foo')
      expect(model.remind_on).to be_nil
    end

    it 'can store nil if the column is nullable' do
      model.update(remind_on: nil)
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

  describe 'time attributes' do
    let(:time) { Time.new(1984, 6, 8, 13, 57, 12) }
    let(:time_string) { '1984-06-08 13:57:12' }
    let(:time) { time_string.respond_to?(:in_time_zone) ? time_string.in_time_zone : Time.parse(time_string) }

    context "with ActiveRecord #{ActiveRecord::VERSION::STRING}" do
      it 'has the defined default as initial value' do
        model.save
        expect(model.reload.published_at).to be == time
      end

      it 'retreive a time instance' do
        model.update(published_at: time)
        expect(model.reload.published_at).to be == time
      end

      if ActiveRecord::Base.time_zone_aware_attributes
        it 'properly cast assigned value to time' do
          model.remind_at = time_string
          expect(model.remind_at).to be == time
        end
      else
        it 'properly cast assigned value to time' do
          model.remind_at = time_string
          expect(model.remind_at).to be == time
        end
      end
    end
  end

  describe 'datetime attributes' do

    let(:datetime) { DateTime.new(1984, 6, 8, 13, 57, 12) }
    let(:datetime_string) { '1984-06-08 13:57:12' }
    let(:time) { datetime_string.respond_to?(:in_time_zone) ? datetime_string.in_time_zone : Time.parse(datetime_string) }

    context "with ActiveRecord #{ActiveRecord::VERSION::STRING}" do
      it 'has the defined default as initial value' do
        model.save
        expect(model.reload.published_at).to be == datetime
      end

      it 'retreive a DateTime instance' do
        model.update(published_at: datetime)
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

    it 'nillify unparsable datetimes' do
      model.update(remind_at: 'foo')
      expect(model.remind_at).to be_nil
    end

    it 'can store nil if the column is nullable' do
      model.update(remind_at: nil)
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

shared_examples 'a store' do |retain_type = true, settings_type = :text|
  let(:model) { described_class.new }

  describe "without connection" do
    before do
      $conn_params = ActiveRecord::Base.remove_connection
    end
    after do
      ActiveRecord::Base.establish_connection $conn_params
    end

    it "does not require a connection to initialize a model" do
      klass = Class.new(ActiveRecord::Base) do
        typed_store :settings do |t|
          t.integer :age
        end
      end
      expect(klass.connected?).to be_falsy
    end
  end

  describe 'model.typed_stores' do
    it "can access keys" do
      stores = model.class.typed_stores
      expect(stores[:settings].keys).to eq [:no_default, :name, :email, :cell_phone, :public, :enabled, :age, :max_length, :rate, :price, :published_on, :remind_on, :published_at_time, :remind_at_time, :published_at, :remind_at, :total_price, :shipping_cost, :grades, :tags, :nickname, :author, :source, :signup, :country]
    end

    it "can access keys even when accessors are not defined" do
      stores = model.class.typed_stores
      expect(stores[:explicit_settings].keys).to eq [:ip_address, :user_agent, :signup]
    end

    it "can access keys even when accessors are partially defined" do
      stores = model.class.typed_stores
      expect(stores[:partial_settings].keys).to eq [:tax_rate_key, :tax_rate]
    end
  end

  it 'does not include blank attribute' do
    expect(model.settings).not_to have_key(:remind_on)
    model.settings = { extra_key: 123 }
    model.save!
    expect(model.settings).not_to have_key(:remind_on)
  end

  describe 'assigning the store' do
    it 'handles mutated value' do
      model.save!
      model.settings[:signup][:apps] ||= []
      model.settings[:signup][:apps] << 123
      expect(model.settings[:signup]).to eq ({
        "apps" => [123]
      })
      expect(model.settings_changed?).to eq true
    end

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

    it 'has indifferent accessor' do
      expect(model.settings[:age]).to eq model.settings['age']
      model.settings['age'] = "40"
      expect(model.settings[:age]).to eq 40
    end

    it 'does not crash on decoding non-hash store value' do
      expect {
        model.settings = String.new
        model.settings
      }.to raise_error ArgumentError, "ActiveRecord::TypedStore expects a hash as a column value, String received"

      expect {
        model.settings = String.new
        model.save!
      }.to raise_error ArgumentError, "ActiveRecord::TypedStore expects a hash as a column value, String received"
    end

    it 'does not crash if column is nil' do
      model.save!
      model.update_column(:settings, nil)

      model.reload
      expect(model.settings).to be_present
    end

    it 'allows to assign custom key' do
      model.settings[:not_existing_key] = 42
      expect(model.settings[:not_existing_key]).to eq 42
      model.save!

      model.reload
      expect(model.settings[:not_existing_key]).to eq 42
    end

    it 'delegates internal methods to the underlying type' do
      expect(model.class.type_for_attribute("settings").type).to eq settings_type
    end
  end

  describe 'attributes' do

    it 'retrieve default if assigned nil and null not allowed' do
      model.update(age: nil)
      expect(model.age).to be == 12
    end

    context 'when column cannot be blank' do
      it 'retreive default if not persisted yet, and nothing was assigned' do
        expect(model.nickname).to be == 'Please enter your nickname'
      end

      it 'retreive default if assigned a blank value' do
        model.update(nickname: '')
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

    it 'does not have dirty accessors' do
      expect(model).not_to respond_to :country_was
    end

    it 'still has casting a default handling' do
      expect(model.settings[:country]).to be == 'Canada'
    end

  end

  describe 'with no accessors' do

    it 'cannot be accessed as a model attribute' do
      expect(model).not_to respond_to :ip_address
      expect(model).not_to respond_to :ip_address=
    end

    it 'cannot be queried' do
      expect(model).not_to respond_to :ip_address?
    end

    it 'cannot be reset' do
      expect(model).not_to respond_to :reset_ip_address!
    end

    it 'does not have dirty accessors' do
      expect(model).not_to respond_to :ip_address_was
    end

    it 'still has casting a default handling' do
      expect(model.explicit_settings[:ip_address]).to be == '127.0.0.1'
    end

  end

  describe 'with some accessors' do

    it 'does not define an attribute' do
      expect(model).not_to respond_to :tax_rate_key
    end

    it 'define an attribute when included in the accessors array' do
      expect(model).to respond_to :tax_rate
    end

  end

  describe '`any` attributes' do

    it 'accept any type' do
      model.update(author: 'George')
      expect(model.reload.author).to be == 'George'

      model.update(author: 42)
      expect(model.reload.author).to be == (retain_type ? 42 : '42')
    end

    it 'still handle default' do
      model.update(source: '')
      expect(model.reload.source).to be == 'web'
    end

    it 'works with default hash' do
      model.signup[:counter] = 123
      model.save!
      expect(model.settings[:signup][:counter]).to eq 123
    end

    it 'works with default hash without affecting unaccessible attributes' do
      model.signup[:counter] = 123
      model.save!
      expect(model.explicit_settings[:signup][:counter]).to be_nil
    end

  end
end

shared_examples 'a db backed model' do

  let(:model) { described_class.new }

  it 'let the underlying db raise if assigned nil on non nullable column' do
    expect {
      model.update(age: nil)
    }.to raise_error(ActiveRecord::StatementInvalid)
  end

  describe "#write_attribute" do
    let(:value) { 12 }
    it "attr_name can be a string" do
      model.send(:write_attribute, 'age', value)
      expect(model.age).to be == value
    end

    it "attr_name can be a symbol" do
      model.send(:write_attribute, :age, value)
      expect(model.age).to be == value
    end
  end

end

shared_examples 'a model supporting arrays' do |pg_native=false|

  let(:model) { described_class.new }

  it 'retrieve an array of values' do
    model.update(grades: [1, 2, 3, 4])
    expect(model.reload.grades).to be == [1, 2, 3, 4]
  end

  it 'cast values inside the array (integer)' do
    model.update(grades: ['1', 2, 3.4])
    expect(model.reload.grades).to be == [1, 2, 3]
  end

  it 'cast values inside the array (string)' do
    model.update(tags: [1, 2.3])
    expect(model.reload.tags).to be == %w(1 2.3)
  end

  it 'accept nil inside array even if collumn is non nullable' do
    model.update(tags: [1, nil])
    expect(model.reload.tags).to be == ['1', nil]
  end

  if !pg_native
    it 'convert non array value as empty array' do
      model.update(grades: 'foo')
      expect(model.reload.grades).to be == []
    end

    it 'accept multidimensianl arrays' do
      model.update(grades: [[1, 2], [3, 4]])
      expect(model.reload.grades).to be == [[1, 2], [3, 4]]
    end
  end

  if pg_native

    it 'raise on non rectangular multidimensianl arrays' do
      expect{
        model.update(grades: [[1, 2], [3, 4, 5]])
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it 'raise on non nil assignation if column is non nullable' do
      expect{
        model.update(tags: nil)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

  else

    it 'accept non rectangular multidimensianl arrays' do
      model.update(grades: [[1, 2], [3, 4, 5]])
      expect(model.reload.grades).to be == [[1, 2], [3, 4, 5]]
    end

    it 'retreive default if assigned null' do
      model.update(tags: nil)
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
  it_should_behave_like 'a model supporting arrays', true
end if defined?(PostgresqlRegularARModel)

describe PostgresJsonTypedStoreModel do
  it_should_behave_like 'any model'
  it_should_behave_like 'a store', true, :json
  it_should_behave_like 'a model supporting arrays'
end if defined?(PostgresJsonTypedStoreModel)

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

describe InheritedTypedStoreModel do
  let(:model) { described_class.new }

  it 'can be serialized' do
    model.update(new_attribute: "foobar")
    expect(model.reload.new_attribute).to be == "foobar"
  end

  it 'is casted' do
    model.update(new_attribute: 42)
    expect(model.settings[:new_attribute]).to be == '42'
  end
end
