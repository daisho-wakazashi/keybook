# spec/models/availability_spec.rb
require 'rails_helper'

RSpec.describe Availability, type: :model do
  let(:user) { create(:user) }
  let(:tomorrow_9am) { (Date.current + 1.day).to_time.utc.change(hour: 9) }
  let(:tomorrow_10am) { (Date.current + 1.day).to_time.utc.change(hour: 10) }
  let(:tomorrow_11am) { (Date.current + 1.day).to_time.utc.change(hour: 11) }
  let(:tomorrow_12pm) { (Date.current + 1.day).to_time.utc.change(hour: 12) }

  describe 'associations' do
    it 'belongs to a user' do
      availability = Availability.new(
        user: user,
        start_time: tomorrow_9am,
        end_time: tomorrow_10am
      )
      expect(availability.user).to eq(user)
    end

    it 'is invalid without a user' do
      availability = Availability.new(
        start_time: tomorrow_9am,
        end_time: tomorrow_10am
      )
      expect(availability).not_to be_valid
    end
  end

  describe 'validations' do
    context 'start_time' do
      it 'is required' do
        availability = Availability.new(
          user: user,
          end_time: tomorrow_10am
        )
        expect(availability).not_to be_valid
        expect(availability.errors[:start_time]).to include("can't be blank")
      end

      it 'cannot be in the past' do
        past_time = 1.hour.ago.utc
        availability = Availability.new(
          user: user,
          start_time: past_time,
          end_time: past_time + 1.hour
        )
        expect(availability).not_to be_valid
        expect(availability.errors[:start_time]).to include("cannot be in the past")
      end

      it 'can be in the future' do
        availability = Availability.new(
          user: user,
          start_time: tomorrow_9am,
          end_time: tomorrow_10am
        )
        expect(availability).to be_valid
      end
    end

    context 'end_time' do
      it 'is required' do
        availability = Availability.new(
          user: user,
          start_time: tomorrow_9am
        )
        expect(availability).not_to be_valid
        expect(availability.errors[:end_time]).to include("can't be blank")
      end

      it 'must be after start_time' do
        availability = Availability.new(
          user: user,
          start_time: tomorrow_10am,
          end_time: tomorrow_9am
        )
        expect(availability).not_to be_valid
        expect(availability.errors[:end_time]).to include("must be after start time")
      end

      it 'cannot equal start_time' do
        availability = Availability.new(
          user: user,
          start_time: tomorrow_9am,
          end_time: tomorrow_9am
        )
        expect(availability).not_to be_valid
        expect(availability.errors[:end_time]).to include("must be after start time")
      end

      it 'is valid when after start_time' do
        availability = Availability.new(
          user: user,
          start_time: tomorrow_9am,
          end_time: tomorrow_10am
        )
        expect(availability).to be_valid
      end
    end

    context 'overlapping time slots' do
      before do
        # Create an existing availability from 09:00 to 11:00
        Availability.create!(
          user: user,
          start_time: tomorrow_9am,
          end_time: tomorrow_11am
        )
      end

      it 'prevents overlapping availability for the same user and date' do
        # Attempt to create overlapping slot from 10:00 to 12:00
        overlapping_availability = Availability.new(
          user: user,
          start_time: tomorrow_10am,
          end_time: tomorrow_12pm
        )
        expect(overlapping_availability).not_to be_valid
        expect(overlapping_availability.errors[:base]).to include("This time slot overlaps with an existing availability")
      end

      it 'prevents creating availability that starts before and ends after existing slot' do
        # Attempt to create slot from 08:00 to 12:00 (encompasses existing 09:00-11:00)
        tomorrow_8am = tomorrow_9am - 1.hour
        overlapping_availability = Availability.new(
          user: user,
          start_time: tomorrow_8am,
          end_time: tomorrow_12pm
        )
        expect(overlapping_availability).not_to be_valid
        expect(overlapping_availability.errors[:base]).to include("This time slot overlaps with an existing availability")
      end

      it 'prevents creating availability that is contained within existing slot' do
        # Attempt to create slot from 09:30 to 10:30 (within existing 09:00-11:00)
        tomorrow_9_30am = tomorrow_9am + 30.minutes
        tomorrow_10_30am = tomorrow_10am + 30.minutes
        overlapping_availability = Availability.new(
          user: user,
          start_time: tomorrow_9_30am,
          end_time: tomorrow_10_30am
        )
        expect(overlapping_availability).not_to be_valid
        expect(overlapping_availability.errors[:base]).to include("This time slot overlaps with an existing availability")
      end

      it 'allows non-overlapping availability on the same date' do
        # Create non-overlapping slot from 11:00 to 12:00 (starts exactly when previous ends)
        non_overlapping_availability = Availability.new(
          user: user,
          start_time: tomorrow_11am,
          end_time: tomorrow_12pm
        )
        expect(non_overlapping_availability).to be_valid
      end

      it 'allows overlapping times for different users' do
        other_user = create(:user, first_name: 'Jane')
        # Create overlapping slot for a different user
        other_availability = Availability.new(
          user: other_user,
          start_time: tomorrow_10am,
          end_time: tomorrow_12pm
        )
        expect(other_availability).to be_valid
      end

      it 'allows overlapping times on different dates' do
        # Create overlapping slot for a different date
        next_day_10am = tomorrow_10am + 1.day
        next_day_12pm = tomorrow_12pm + 1.day
        different_date_availability = Availability.new(
          user: user,
          start_time: next_day_10am,
          end_time: next_day_12pm
        )
        expect(different_date_availability).to be_valid
      end
    end

    context 'with all valid attributes' do
      it 'creates a valid availability' do
        availability = Availability.new(
          user: user,
          start_time: tomorrow_9am,
          end_time: tomorrow_10am
        )
        expect(availability).to be_valid
      end
    end

    context 'with multiple missing attributes' do
      it 'shows all validation errors' do
        availability = Availability.new(user: user)
        expect(availability).not_to be_valid
        expect(availability.errors[:start_time]).to include("can't be blank")
        expect(availability.errors[:end_time]).to include("can't be blank")
      end
    end
  end

  describe 'updating existing availabilities' do
    let!(:availability) do
      Availability.create!(
        user: user,
        start_time: tomorrow_9am,
        end_time: tomorrow_11am
      )
    end

    it 'allows updating the same record without triggering overlap validation' do
      tomorrow_11_30am = tomorrow_11am + 30.minutes
      availability.end_time = tomorrow_11_30am
      expect(availability).to be_valid
      expect(availability.save).to be true
    end

    it 'prevents updating to overlap with another availability' do
      # Create another availability
      tomorrow_2pm = tomorrow_9am.change(hour: 14)
      tomorrow_3pm = tomorrow_9am.change(hour: 15)
      Availability.create!(
        user: user,
        start_time: tomorrow_2pm,
        end_time: tomorrow_3pm
      )

      # Try to update first availability to overlap with second
      tomorrow_1pm = tomorrow_9am.change(hour: 13)
      tomorrow_2_30pm = tomorrow_2pm + 30.minutes
      availability.start_time = tomorrow_1pm
      availability.end_time = tomorrow_2_30pm
      expect(availability).not_to be_valid
      expect(availability.errors[:base]).to include("This time slot overlaps with an existing availability")
    end
  end
end
