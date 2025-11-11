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
      let(:availabilities_json) { [ datetime.iso8601 ].to_json }

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

      it 'creates five separate one-hour availabilities' do
        expect {
          described_class.perform(user, availabilities_json)
        }.to change { user.availabilities.count }.by(5)
      end

      it 'creates each availability spanning one hour' do
        described_class.perform(user, availabilities_json)

        availabilities = user.availabilities.order(:start_time)
        (0..4).each do |i|
          expect(availabilities[i].start_time).to be_within(1.second).of(base_time + i.hours)
          expect(availabilities[i].end_time).to be_within(1.second).of(base_time + (i + 1).hours)
        end
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

      it 'creates five separate one-hour availabilities' do
        expect {
          described_class.perform(user, availabilities_json)
        }.to change { user.availabilities.count }.by(5)
      end

      it 'creates three one-hour availabilities on day 1' do
        described_class.perform(user, availabilities_json)

        day1_availabilities = user.availabilities.where('start_time >= ? AND start_time < ?', day1.beginning_of_day, day1.end_of_day).order(:start_time)
        expect(day1_availabilities.count).to eq(3)
        expect(day1_availabilities[0].start_time).to be_within(1.second).of(day1)
        expect(day1_availabilities[0].end_time).to be_within(1.second).of(day1 + 1.hour)
        expect(day1_availabilities[1].start_time).to be_within(1.second).of(day1 + 1.hour)
        expect(day1_availabilities[1].end_time).to be_within(1.second).of(day1 + 2.hours)
        expect(day1_availabilities[2].start_time).to be_within(1.second).of(day1 + 2.hours)
        expect(day1_availabilities[2].end_time).to be_within(1.second).of(day1 + 3.hours)
      end

      it 'creates two one-hour availabilities on day 2' do
        described_class.perform(user, availabilities_json)

        day2_availabilities = user.availabilities.where('start_time >= ? AND start_time < ?', day2.beginning_of_day, day2.end_of_day).order(:start_time)
        expect(day2_availabilities.count).to eq(2)
        expect(day2_availabilities[0].start_time).to be_within(1.second).of(day2)
        expect(day2_availabilities[0].end_time).to be_within(1.second).of(day2 + 1.hour)
        expect(day2_availabilities[1].start_time).to be_within(1.second).of(day2 + 1.hour)
        expect(day2_availabilities[1].end_time).to be_within(1.second).of(day2 + 2.hours)
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

      it 'handles unsorted input and creates three separate availabilities' do
        expect {
          described_class.perform(user, availabilities_json)
        }.to change { user.availabilities.count }.by(3)
      end

      it 'creates each availability spanning one hour' do
        described_class.perform(user, availabilities_json)

        availabilities = user.availabilities.order(:start_time)
        expect(availabilities[0].start_time).to be_within(1.second).of(base_time)
        expect(availabilities[0].end_time).to be_within(1.second).of(base_time + 1.hour)
        expect(availabilities[1].start_time).to be_within(1.second).of(base_time + 1.hour)
        expect(availabilities[1].end_time).to be_within(1.second).of(base_time + 2.hours)
        expect(availabilities[2].start_time).to be_within(1.second).of(base_time + 2.hours)
        expect(availabilities[2].end_time).to be_within(1.second).of(base_time + 3.hours)
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

      it 'handles duplicates by deduplicating and creates two availabilities' do
        expect {
          described_class.perform(user, availabilities_json)
        }.to change { user.availabilities.count }.by(2)
      end

      it 'creates two separate one-hour availabilities without duplication' do
        described_class.perform(user, availabilities_json)

        availabilities = user.availabilities.order(:start_time)
        expect(availabilities[0].start_time).to be_within(1.second).of(base_time)
        expect(availabilities[0].end_time).to be_within(1.second).of(base_time + 1.hour)
        expect(availabilities[1].start_time).to be_within(1.second).of(base_time + 1.hour)
        expect(availabilities[1].end_time).to be_within(1.second).of(base_time + 2.hours)
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
        }.to change { user.availabilities.count }.by(2)
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

      it 'creates two separate one-hour availabilities from valid datetimes' do
        described_class.perform(user, mixed_availabilities_json)

        availabilities = user.availabilities.order(:start_time)
        expect(availabilities[0].start_time).to be_within(1.second).of(base_time)
        expect(availabilities[0].end_time).to be_within(1.second).of(base_time + 1.hour)
        expect(availabilities[1].start_time).to be_within(1.second).of(base_time + 1.hour)
        expect(availabilities[1].end_time).to be_within(1.second).of(base_time + 2.hours)
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
end
