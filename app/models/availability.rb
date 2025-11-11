class Availability < ApplicationRecord
  belongs_to :user

  # Validations
  validates :start_time, presence: true
  validates :end_time, presence: true

  validate :end_time_after_start_time
  validate :no_overlapping_slots
  validate :start_time_not_in_past

  private

  def end_time_after_start_time
    return unless start_time && end_time

    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end

  def no_overlapping_slots
    return unless user && start_time && end_time

    start_of_day = start_time.utc.beginning_of_day
    end_of_day = start_time.utc.end_of_day

    overlapping = user.availabilities
                      .where.not(id: id)
                      .where("start_time >= ? AND start_time < ?", start_of_day, end_of_day)
                      .where("start_time < ? AND end_time > ?", end_time, start_time)

    if overlapping.exists?
      errors.add(:base, "This time slot overlaps with an existing availability")
    end
  end

  def start_time_not_in_past
    return unless start_time

    if start_time < Time.current.utc
      errors.add(:start_time, "cannot be in the past")
    end
  end
end
