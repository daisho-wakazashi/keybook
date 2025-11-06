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

      # Group datetimes by date and find continuous blocks
      blocks = []
      datetimes.group_by(&:to_date).each do |_date, day_times|
        blocks.concat(find_continuous_blocks(day_times))
      end

      blocks
    end
  end

  def find_continuous_blocks(sorted_times)
    return [] if sorted_times.empty?

    blocks = []
    current_block_start = sorted_times.first
    current_block_end = sorted_times.first + 1.hour

    # Handle single datetime case
    if sorted_times.size == 1
      blocks << { start_time: current_block_start, end_time: current_block_end }
      return blocks
    end

    sorted_times.each_cons(2) do |current_time, next_time|
      if next_time == current_time + 1.hour
        # Extend current block
        current_block_end = next_time + 1.hour
      else
        # Save current block and start new one
        blocks << { start_time: current_block_start, end_time: current_block_end }
        current_block_start = next_time
        current_block_end = next_time + 1.hour
      end
    end

    # Add the last block
    blocks << { start_time: current_block_start, end_time: current_block_end }

    blocks
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
