class CreateBookingForAvailability
  include UseCase

  def initialize(booker, availability_id)
    @booker = booker
    @availability_id = availability_id
  end

  def perform
    return unless booker_is_tenant?

    create_booking_with_lock
  end

  private

  def booker_is_tenant?
    return true if @booker.role_tenant?

    errors.add(:base, "user is not able to make bookings")
    false
  end

  def create_booking_with_lock
    # Use a transaction with pessimistic locking to prevent race conditions
    # lock! will block concurrent requests until the lock is released
    Booking.transaction do
      availability = Availability.lock.find(@availability_id)

      # Check if availability is already booked
      if availability.booking.present?
        errors.add(:availability, "is already booked")
        raise ActiveRecord::Rollback
      end

      booking = Booking.new(booker: @booker, availability: availability)

      unless booking.save
        errors.add(:base, booking.errors.full_messages)
        raise ActiveRecord::Rollback
      end
    end
  rescue ActiveRecord::RecordNotFound
    errors.add(:availability, "not found")
  rescue ActiveRecord::StatementInvalid => e
    # Handle database-level errors including deadlocks
    if e.message.include?("deadlock")
      errors.add(:base, "Unable to complete booking due to concurrent requests. Please try again.")
    else
      errors.add(:base, "A database error occurred: #{e.message}")
    end
  end
end
