require 'rails_helper'

RSpec.describe CreateAvailabilitiesForUser, type: :service do
  let(:user) { create(:user, :property_manager) }

  describe '.perform' do
    it 'returns an instance of the service' do
      availabilities_json = [].to_json
      result = described_class.perform(user, availabilities_json)

      expect(result).to be_a(described_class)
    end
  end

  describe '#perform' do
    context 'with a single datetime' do
      let(:datetime) { 1.day.from_now.change(hour: 9, min: 0) }
      let(:availabilities_json) { [datetime.iso8601].to_json }

      it 'creates one availability for the user' do
        expect {
          described_class.perform(user, availabilities_json)
        }.to change { user.availabilities.count }.by(1)
      end

      it 'creates availability spanning one hour' do
        described_class.perform(user, availabilities_json)

        availability = user.availabilities.last
        expect(availability.start_time).to be_within(1.second).of(datetime)
        expect(availability.end_time).to be_within(1.second).of(datetime + 1.hour)
      end

      it 'returns success' do
        result = described_class.perform(user, availabilities_json)

        expect(result).to be_success
      end
    end

    context 'with two consecutive hours' do
      let(:base_time) { 1.day.from_now.change(hour: 9, min: 0) }
      let(:availabilities_json) do
        [
          base_time.iso8601,
          (base_time + 1.hour).iso8601
        ].to_json
      end

      it 'creates a single grouped availability' do
        expect {
          described_class.perform(user, availabilities_json)
        }.to change { user.availabilities.count }.by(1)
      end

      it 'creates availability spanning two hours' do
        described_class.perform(user, availabilities_json)

        availability = user.availabilities.last
        expect(availability.start_time).to be_within(1.second).of(base_time)
        expect(availability.end_time).to be_within(1.second).of(base_time + 2.hours)
      end

      it 'returns success' do
        result = described_class.perform(user, availabilities_json)

        expect(result).to be_success
      end
    end

    context 'with three consecutive hours' do
      let(:base_time) { 1.day.from_now.change(hour: 14, min: 0) }
      let(:availabilities_json) do
        [
          base_time.iso8601,
          (base_time + 1.hour).iso8601,
          (base_time + 2.hours).iso8601
        ].to_json
      end

      it 'creates a single grouped availability' do
        expect {
          described_class.perform(user, availabilities_json)
        }.to change { user.availabilities.count }.by(1)
      end

      it 'creates availability spanning three hours' do
        described_class.perform(user, availabilities_json)

        availability = user.availabilities.last
        expect(availability.start_time).to be_within(1.second).of(base_time)
        expect(availability.end_time).to be_within(1.second).of(base_time + 3.hours)
      end
    end

    context 'with five consecutive hours' do
      let(:base_time) { 2.days.from_now.change(hour: 10, min: 0) }
      let(:availabilities_json) do
        [
          base_time.iso8601,
          (base_time + 1.hour).iso8601,
          (base_time + 2.hours).iso8601,
          (base_time + 3.hours).iso8601,
          (base_time + 4.hours).iso8601
        ].to_json
      end

      it 'creates a single grouped availability' do
        expect {
          described_class.perform(user, availabilities_json)
        }.to change { user.availabilities.count }.by(1)
      end

      it 'creates availability spanning five hours' do
        described_class.perform(user, availabilities_json)

        availability = user.availabilities.last
        expect(availability.start_time).to be_within(1.second).of(base_time)
        expect(availability.end_time).to be_within(1.second).of(base_time + 5.hours)
      end
    end

    context 'with non-consecutive hours on same day' do
      let(:base_time) { 1.day.from_now.change(hour: 9, min: 0) }
      let(:availabilities_json) do
        [
          base_time.iso8601,
          (base_time + 1.hour).iso8601,
          (base_time + 4.hours).iso8601,  # Gap of 2 hours
          (base_time + 5.hours).iso8601
        ].to_json
      end

      it 'creates two separate availabilities' do
        expect {
          described_class.perform(user, availabilities_json)
        }.to change { user.availabilities.count }.by(2)
      end

      it 'creates first availability for 9-11' do
        described_class.perform(user, availabilities_json)

        first_availability = user.availabilities.order(:start_time).first
        expect(first_availability.start_time).to be_within(1.second).of(base_time)
        expect(first_availability.end_time).to be_within(1.second).of(base_time + 2.hours)
      end

      it 'creates second availability for 13-15' do
        described_class.perform(user, availabilities_json)

        second_availability = user.availabilities.order(:start_time).last
        expect(second_availability.start_time).to be_within(1.second).of(base_time + 4.hours)
        expect(second_availability.end_time).to be_within(1.second).of(base_time + 6.hours)
      end
    end

    context 'with multiple groups on different days' do
      let(:day1) { 1.day.from_now.change(hour: 9, min: 0) }
      let(:day2) { 2.days.from_now.change(hour: 14, min: 0) }
      let(:availabilities_json) do
        [
          day1.iso8601,
          (day1 + 1.hour).iso8601,
          (day1 + 2.hours).iso8601,
          day2.iso8601,
          (day2 + 1.hour).iso8601
        ].to_json
      end

      it 'creates two availabilities (one per day)' do
        expect {
          described_class.perform(user, availabilities_json)
        }.to change { user.availabilities.count }.by(2)
      end

      it 'creates first availability spanning 3 hours on day 1' do
        described_class.perform(user, availabilities_json)

        first_day_availability = user.availabilities.where('start_time >= ?', day1.beginning_of_day).first
        expect(first_day_availability.start_time).to be_within(1.second).of(day1)
        expect(first_day_availability.end_time).to be_within(1.second).of(day1 + 3.hours)
      end

      it 'creates second availability spanning 2 hours on day 2' do
        described_class.perform(user, availabilities_json)

        second_day_availability = user.availabilities.where('start_time >= ?', day2.beginning_of_day).first
        expect(second_day_availability.start_time).to be_within(1.second).of(day2)
        expect(second_day_availability.end_time).to be_within(1.second).of(day2 + 2.hours)
      end
    end

    context 'with unsorted datetimes' do
      let(:base_time) { 1.day.from_now.change(hour: 10, min: 0) }
      let(:availabilities_json) do
        [
          (base_time + 2.hours).iso8601,
          base_time.iso8601,
          (base_time + 1.hour).iso8601
        ].to_json
      end

      it 'handles unsorted input and groups correctly' do
        expect {
          described_class.perform(user, availabilities_json)
        }.to change { user.availabilities.count }.by(1)
      end

      it 'creates availability spanning three hours' do
        described_class.perform(user, availabilities_json)

        availability = user.availabilities.last
        expect(availability.start_time).to be_within(1.second).of(base_time)
        expect(availability.end_time).to be_within(1.second).of(base_time + 3.hours)
      end
    end

    context 'with duplicate hours' do
      let(:base_time) { 1.day.from_now.change(hour: 9, min: 0) }
      let(:availabilities_json) do
        [
          base_time.iso8601,
          base_time.iso8601,  # Duplicate
          (base_time + 1.hour).iso8601
        ].to_json
      end

      it 'handles duplicates without creating overlapping availabilities' do
        expect {
          described_class.perform(user, availabilities_json)
        }.to change { user.availabilities.count }.by(1)
      end

      it 'creates a single availability without duplication' do
        described_class.perform(user, availabilities_json)

        availability = user.availabilities.last
        expect(availability.start_time).to be_within(1.second).of(base_time)
        expect(availability.end_time).to be_within(1.second).of(base_time + 2.hours)
      end
    end

    context 'with invalid JSON' do
      let(:invalid_json) { 'not valid json{[' }

      it 'does not create any availabilities' do
        expect {
          described_class.perform(user, invalid_json)
        }.not_to change { user.availabilities.count }
      end

      it 'returns failure with error message' do
        result = described_class.perform(user, invalid_json)

        expect(result).not_to be_success
        expect(result.errors[:base]).to include(I18n.t('property_managers.calendar.invalid_data'))
      end
    end

    context 'with invalid datetime string' do
      let(:invalid_availabilities_json) do
        [
          "not-a-valid-datetime"
        ].to_json
      end

      it 'does not create any availabilities' do
        expect {
          described_class.perform(user, invalid_availabilities_json)
        }.not_to change { user.availabilities.count }
      end

      it 'notifies about invalid datetime via Rails event' do
        expect(Rails.event).to receive(:notify).with(
          "availability.invalid_datetime",
          hash_including(
            user_id: user.id,
            invalid_datetime: "not-a-valid-datetime",
            service: "CreateAvailabilitiesForUser"
          )
        )

        described_class.perform(user, invalid_availabilities_json)
      end

      it 'returns success when all datetimes are invalid' do
        result = described_class.perform(user, invalid_availabilities_json)
        expect(result).to be_success
      end
    end

    context 'with mixed valid and invalid datetime strings' do
      let(:base_time) { 1.day.from_now.change(hour: 9, min: 0) }
      let(:mixed_availabilities_json) do
        [
          base_time.iso8601,
          "not-a-valid-datetime",
          (base_time + 1.hour).iso8601
        ].to_json
      end

      it 'creates availabilities for valid datetimes only' do
        expect {
          described_class.perform(user, mixed_availabilities_json)
        }.to change { user.availabilities.count }.by(1)
      end

      it 'notifies about invalid datetime' do
        expect(Rails.event).to receive(:notify).with(
          "availability.invalid_datetime",
          hash_including(
            user_id: user.id,
            invalid_datetime: "not-a-valid-datetime",
            service: "CreateAvailabilitiesForUser"
          )
        )

        described_class.perform(user, mixed_availabilities_json)
      end

      it 'creates grouped availability from valid datetimes' do
        described_class.perform(user, mixed_availabilities_json)

        availability = user.availabilities.last
        expect(availability.start_time).to be_within(1.second).of(base_time)
        expect(availability.end_time).to be_within(1.second).of(base_time + 2.hours)
      end
    end

    context 'with overlapping availabilities' do
      let!(:existing_availability) do
        create(:availability,
               user: user,
               start_time: 1.day.from_now.change(hour: 10, min: 0),
               end_time: 1.day.from_now.change(hour: 12, min: 0))
      end

      let(:overlapping_json) do
        [
          1.day.from_now.change(hour: 11, min: 0).iso8601
        ].to_json
      end

      it 'does not create overlapping availability' do
        expect {
          described_class.perform(user, overlapping_json)
        }.not_to change { user.availabilities.count }
      end

      it 'returns failure with overlap error' do
        result = described_class.perform(user, overlapping_json)

        expect(result).not_to be_success
        expect(result.errors.full_messages.join).to match(/overlaps/i)
      end
    end

    context 'with empty array' do
      let(:empty_json) { [].to_json }

      it 'does not create any availabilities' do
        expect {
          described_class.perform(user, empty_json)
        }.not_to change { user.availabilities.count }
      end

      it 'returns success' do
        result = described_class.perform(user, empty_json)

        expect(result).to be_success
      end
    end

    context 'with past times' do
      let(:past_availabilities_json) do
        [
          1.day.ago.change(hour: 9, min: 0).iso8601
        ].to_json
      end

      it 'does not create availability for past times' do
        expect {
          described_class.perform(user, past_availabilities_json)
        }.not_to change { user.availabilities.count }
      end

      it 'returns failure with validation error' do
        result = described_class.perform(user, past_availabilities_json)

        expect(result).not_to be_success
        expect(result.errors.full_messages.join).to match(/past/i)
      end
    end
  end

  describe '#success?' do
    context 'when perform succeeds' do
      let(:valid_json) do
        [
          1.day.from_now.change(hour: 9, min: 0).iso8601
        ].to_json
      end

      it 'returns true' do
        service = described_class.new(user, valid_json)
        service.perform

        expect(service).to be_success
        expect(service.success?).to be true
      end
    end

    context 'when perform fails' do
      let(:invalid_json) { 'invalid' }

      it 'returns false' do
        service = described_class.new(user, invalid_json)
        service.perform

        expect(service).not_to be_success
        expect(service.success?).to be false
      end
    end
  end
end
