require 'rails_helper'

RSpec.describe Booking, type: :model do
  describe 'associations' do
    it 'belongs to booker' do
      booking = Booking.reflect_on_association(:booker)
      expect(booking.macro).to eq(:belongs_to)
      expect(booking.options[:class_name]).to eq('User')
    end

    it 'belongs to availability' do
      booking = Booking.reflect_on_association(:availability)
      expect(booking.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    let(:tenant) { create(:user, :tenant) }
    let(:property_manager) { create(:user, :property_manager) }
    let(:availability) { create(:availability, user: property_manager) }

    context 'when booker is a tenant' do
      it 'is valid' do
        booking = build(:booking, booker: tenant, availability: availability)
        expect(booking).to be_valid
      end
    end

    context 'when booker is not a tenant' do
      it 'is invalid' do
        booking = build(:booking, booker: property_manager, availability: availability)
        expect(booking).not_to be_valid
        expect(booking.errors[:booker]).to include('must be a tenant')
      end
    end
  end

  describe 'uniqueness constraint' do
    let(:tenant) { create(:user, :tenant) }
    let(:another_tenant) { create(:user, :tenant) }
    let(:property_manager) { create(:user, :property_manager) }
    let(:availability) { create(:availability, user: property_manager) }

    it 'allows only one booking per availability' do
      create(:booking, booker: tenant, availability: availability)
      duplicate_booking = build(:booking, booker: another_tenant, availability: availability)

      expect(duplicate_booking).not_to be_valid
      expect(duplicate_booking.errors[:availability_id]).to include('has already been taken')
    end
  end
end
