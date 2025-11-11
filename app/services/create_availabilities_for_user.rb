class CreateAvailabilitiesForUser
  include UseCase

  def initialize(user, availabilities_json)
    @availabilities_json = availabilities_json
    @user = user
  end

  def perform
    create_availabilities
  rescue JSON::ParserError
    errors.add(:base, I18n.t("property_managers.calendar.invalid_data"))
  end

  def errors_full_messages
    return [] unless errors.any?
    errors.full_messages
  end

  private

  def create_availabilities
    # We could speed this up with nested_attributes or a single create call but it's a
    # trade-off with speed vs convenience of at least being able to add some availability
    # windows if one fails.
    # I also didn't include any locking as realistically, availability is only done at a user
    # level so only one authed user should be able to update their availability at any time.
    grouped_availabilities.each do |avail_params|
        availability = @user.availabilities.build(
          start_time: avail_params[:start_time],
          end_time: avail_params[:end_time]
        )

        unless availability.save
          puts availability.errors.full_messages
          errors.add(:base, availability.errors.full_messages)
        end
      end
  end

  def grouped_availabilities
    @grouped_availabilities ||= begin
      datetimes = parse_and_validate_datetimes

      return [] if datetimes.empty?

      # Create one-hour availability slots for each datetime
      datetimes.map do |datetime|
        { start_time: datetime, end_time: datetime + 1.hour }
      end
    end
  end

  def parsed_datetimes
    @parsed_datetimes ||= JSON.parse(@availabilities_json)
  end

  def parse_and_validate_datetimes
    # Parse and deduplicate datetimes, then sort
    parsed_datetimes.filter_map do |dt|
      parsed = Time.zone.parse(dt)

      if parsed.nil?
        Rails.event.notify("availability.invalid_datetime",
          user_id: @user.id,
          invalid_datetime: dt,
          service: self.class.name
        )
      end

      parsed
    end.uniq.sort
  end
end
