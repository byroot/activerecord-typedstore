require 'spec_helper'

describe ActiveRecord::TypedStore::TypedHash do

  def create_hash_class(*args)
    described_class.create([ActiveRecord::TypedStore::Field.new(*args)])
  end

  def build_hash(*args)
    create_hash_class(*args).new
  end

  let(:hash) { build_hash(*column) }

  let(:hash_class) { create_hash_class(*column) }

  context 'nullable column without default' do

    let(:column) { ['age', :integer] }

    describe '.new' do

      it 'apply casting' do
        hash = hash_class.new(age: '24')
        expect(hash[:age]).to be == 24
      end

      it "accepts hashy constructor" do
        object = double(to_h: { age: '24' })
        hash = hash_class.new(object)
        expect(hash[:age]).to eq 24
      end
    end

    describe '#initialize' do

      it 'has nil as default value' do
        expect(hash[:age]).to be_nil
      end

    end

    describe '#[]=' do

      it 'apply casting' do
        hash[:age] = '24'
        expect(hash[:age]).to be == 24
      end

      it 'can be nil' do
        hash[:age] = nil
        expect(hash[:age]).to be_nil
      end

    end

    describe '#merge!' do

      it 'apply casting' do
        hash.merge!(age: '24')
        expect(hash[:age]).to be == 24
      end

      it 'can be nil' do
        hash.merge!(age: nil)
        expect(hash[:age]).to be_nil
      end

    end

  end

  context 'nullable column with default' do

    let(:column) { ['age', :integer, default: 42] }

    describe '#initialize' do

      it 'has the default value' do
        expect(hash[:age]).to be == 42
      end

    end

    describe '#[]=' do

      it 'apply casting' do
        hash[:age] = '24'
        expect(hash[:age]).to be == 24
      end

      it 'can be nil' do
        hash[:age] = nil
        expect(hash[:age]).to be_nil
      end

    end

    describe '#merge!' do

      it 'apply casting' do
        hash.merge!(age: '24')
        expect(hash[:age]).to be == 24
      end

      it 'can be nil' do
        hash.merge!(age: nil)
        expect(hash[:age]).to be_nil
      end

    end

  end

  context 'non nullable column with default' do

    let(:column) { ['age', :integer, null: false, default: 42] }

    describe '#intialize' do

      it 'has the default value' do
        expect(hash[:age]).to be == 42
      end

    end

    describe '#[]=' do

      it 'apply casting' do
        hash[:age] = '24'
        expect(hash[:age]).to be == 24
      end

      it 'cannot be nil' do
        hash[:age] = nil
        expect(hash[:age]).to be == 42
      end

    end

    describe '#merge!' do

      it 'apply casting' do
        hash.merge!(age: '24')
        expect(hash[:age]).to be == 24
      end

      it 'cannot be nil' do
        hash.merge!(age: nil)
        expect(hash[:age]).to be == 42
      end

    end

  end

  context 'non blankable column with default' do

    let(:column) { ['source', :string, blank: false, default: 'web'] }

    describe '#intialize' do

      it 'has the default value' do
        expect(hash[:source]).to be == 'web'
      end

    end

    describe '#[]=' do

      it 'apply casting' do
        hash[:source] = :mailing
        expect(hash[:source]).to be == 'mailing'
      end

      it 'cannot be nil' do
        hash[:source] = nil
        expect(hash[:source]).to be == 'web'
      end

      it 'cannot be blank' do
        hash[:source] = ''
        expect(hash[:source]).to be == 'web'
      end

    end

    describe '#merge!' do

      it 'apply casting' do
        hash.merge!(source: :mailing)
        expect(hash[:source]).to be == 'mailing'
      end

      it 'cannot be nil' do
        hash.merge!(source: nil)
        expect(hash[:source]).to be == 'web'
      end

      it 'cannot be blank' do
        hash.merge!(source: '')
        expect(hash[:source]).to be == 'web'
      end

    end

    describe '#except' do

      it 'does not set the default for ignored keys' do
        hash = hash_class.new(source: 'foo')
        expect(hash.except(:source)).to_not have_key(:source)
      end

    end

    describe '#slice' do

      it 'does not set the default for ignored keys' do
        hash = hash_class.new(source: 'foo')
        expect(hash.slice(:not_source)).to_not have_key(:source)
      end

    end

  end

  context 'unknown columns' do
    let(:column) { ['age', :integer] }

    it 'can be assigned' do
      hash = hash_class.new
      hash[:unknown_key] = 42
      expect(hash[:unknown_key]).to be == 42
    end
  end
end
