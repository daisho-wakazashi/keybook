# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    context 'first_name' do
      it 'is required' do
        user = User.new(last_name: 'Doe', role: :property_manager)
        expect(user).not_to be_valid
        expect(user.errors[:first_name]).to include("can't be blank")
      end

      it 'is valid when present' do
        user = User.new(first_name: 'John', last_name: 'Doe', role: :property_manager)
        expect(user).to be_valid
      end
    end

    context 'last_name' do
      it 'is required' do
        user = User.new(first_name: 'John', role: :property_manager)
        expect(user).not_to be_valid
        expect(user.errors[:last_name]).to include("can't be blank")
      end

      it 'is valid when present' do
        user = User.new(first_name: 'John', last_name: 'Doe', role: :property_manager)
        expect(user).to be_valid
      end
    end

    context 'role' do
      it 'is required' do
        user = User.new(first_name: 'John', last_name: 'Doe')
        expect(user).not_to be_valid
        expect(user.errors[:role]).to include("can't be blank")
      end

      it 'accepts property_manager as a valid role' do
        user = User.new(first_name: 'John', last_name: 'Doe', role: :property_manager)
        expect(user).to be_valid
        expect(user.role).to eq('property_manager')
      end

      it 'accepts tenant as a valid role' do
        user = User.new(first_name: 'Jane', last_name: 'Smith', role: :tenant)
        expect(user).to be_valid
        expect(user.role).to eq('tenant')
      end

      it 'rejects invalid role values' do
        expect {
          User.new(first_name: 'John', last_name: 'Doe', role: :admin)
        }.to raise_error(ArgumentError, "'admin' is not a valid role")
      end

      it 'accepts role as a string' do
        user = User.new(first_name: 'John', last_name: 'Doe', role: 'property_manager')
        expect(user).to be_valid
        expect(user.role).to eq('property_manager')
      end
    end

    context 'with all valid attributes' do
      it 'creates a valid user' do
        user = User.new(
          first_name: 'John',
          last_name: 'Doe',
          role: :property_manager
        )
        expect(user).to be_valid
      end
    end

    context 'with multiple missing attributes' do
      it 'shows all validation errors' do
        user = User.new
        expect(user).not_to be_valid
        expect(user.errors[:first_name]).to include("can't be blank")
        expect(user.errors[:last_name]).to include("can't be blank")
        expect(user.errors[:role]).to include("can't be blank")
      end
    end
  end
end
