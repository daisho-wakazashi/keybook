require 'rails_helper'

RSpec.describe CreateBookingForAvailability, type: :service do
  let(:tenant) { create(:user, :tenant) }
  let(:property_manager) { create(:user, :property_manager) }
  let(:availability) { create(:availability, user: property_manager) }

  describe '.perform' do
    it 'returns an instance of the service' do
      result = described_class.perform(tenant, availability.id)

      expect(result).to be_a(described_class)
    end
  end

  describe '#perform' do
    context 'with valid inputs' do
      it 'creates a booking for the availability' do
        expect {
          described_class.perform(tenant, availability.id)
        }.to change { Booking.count }.by(1)
      end

      it 'associates the booking with the correct booker' do
        described_class.perform(tenant, availability.id)

        booking = Booking.last
        expect(booking.booker).to eq(tenant)
      end

      it 'associates the booking with the correct availability' do
        described_class.perform(tenant, availability.id)

        booking = Booking.last
        expect(booking.availability).to eq(availability)
      end

      it 'returns success' do
        result = described_class.perform(tenant, availability.id)

        expect(result).to be_success
      end
    end

    context 'when availability does not exist' do
      it 'does not create a booking' do
        expect {
          described_class.perform(tenant, 999_999)
        }.not_to change { Booking.count }
      end

      it 'returns failure with error message' do
        result = described_class.perform(tenant, 999_999)

        expect(result).not_to be_success
        expect(result.errors[:availability]).to include('not found')
      end
    end

    context 'when availability is already booked' do
      let!(:existing_booking) { create(:booking, availability: availability) }

      it 'does not create another booking' do
        expect {
          described_class.perform(tenant, availability.id)
        }.not_to change { Booking.count }
      end

      it 'returns failure with error message' do
        result = described_class.perform(tenant, availability.id)

        expect(result).not_to be_success
        expect(result.errors[:availability]).to include('is already booked')
      end
    end

    context 'when booker is not a tenant' do
      it 'does not create a booking' do
        expect {
          described_class.perform(property_manager, availability.id)
        }.not_to change { Booking.count }
      end

      it 'returns failure with validation error' do
        result = described_class.perform(property_manager, availability.id)

        expect(result).not_to be_success
        expect(result.errors[:base].join).to match(/not able to make bookings/i)
      end
    end

    context 'with concurrent booking requests' do
      let(:another_tenant) { create(:user, :tenant) }

      it 'allows only one booking to succeed' do
        # Simulate concurrent requests using threads
        threads = [
          Thread.new { described_class.perform(tenant, availability.id) },
          Thread.new { described_class.perform(another_tenant, availability.id) }
        ]

        results = threads.map(&:value)

        # Exactly one should succeed
        successful_results = results.select(&:success?)
        failed_results = results.reject(&:success?)

        expect(successful_results.count).to eq(1)
        expect(failed_results.count).to eq(1)
        expect(Booking.where(availability: availability).count).to eq(1)
      end

      it 'the failed request has an appropriate error message' do
        threads = [
          Thread.new { described_class.perform(tenant, availability.id) },
          Thread.new { described_class.perform(another_tenant, availability.id) }
        ]

        results = threads.map(&:value)
        failed_result = results.find { |r| !r.success? }

        expect(failed_result.errors[:availability]).to include('is already booked')
      end
    end

    context 'when locking fails' do
      before do
        # Stub to simulate a database error
        allow(Availability).to receive(:lock).and_raise(
          ActiveRecord::StatementInvalid.new("database error")
        )
      end

      it 'does not create a booking' do
        expect {
          described_class.perform(tenant, availability.id)
        }.not_to change { Booking.count }
      end

      it 'returns failure with error message' do
        result = described_class.perform(tenant, availability.id)

        expect(result).not_to be_success
        expect(result.errors[:base].join).to match(/database error/i)
      end
    end

    context 'when a deadlock occurs' do
      before do
        # Simulate a deadlock error
        allow(Availability).to receive(:lock).and_raise(
          ActiveRecord::StatementInvalid.new("deadlock detected")
        )
      end

      it 'returns failure with user-friendly error message' do
        result = described_class.perform(tenant, availability.id)

        expect(result).not_to be_success
        expect(result.errors[:base].join).to match(/concurrent requests/i)
      end
    end
  end

  describe '#success?' do
    context 'when perform succeeds' do
      it 'returns true' do
        service = described_class.new(tenant, availability.id)
        service.perform

        expect(service).to be_success
        expect(service.success?).to be true
      end
    end

    context 'when perform fails' do
      let!(:existing_booking) { create(:booking, availability: availability) }

      it 'returns false' do
        service = described_class.new(tenant, availability.id)
        service.perform

        expect(service).not_to be_success
        expect(service.success?).to be false
      end
    end
  end
end
