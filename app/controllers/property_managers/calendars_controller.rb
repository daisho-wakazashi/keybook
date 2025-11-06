module PropertyManagers
  class CalendarsController < ApplicationController
    before_action :set_date_range

    def show
      @availabilities = current_user.availabilities
                                    .where(start_time: @week_start.beginning_of_day..@week_end.end_of_day)
                                    .order(:start_time)
    end

    def create
      creation_service = CreateAvailabilitiesForUser.perform(current_user, params[:availabilities])

      if creation_service.success?
        redirect_to property_managers_calendar_path(date: @date),
                    notice: t("property_managers.calendar.created"),
                    status: :created
      else
        flash[:alert] = t("property_managers.calendar.creation_errors", errors: creation_service.errors_full_messages.join(", "))
        redirect_to property_managers_calendar_path(date: @date), status: :unprocessable_entity
      end
    end

    private

    def set_date_range
      @date = params[:date] ? Date.parse(params[:date]) : Date.current
      @week_start = @date.beginning_of_week(:sunday)
      @week_end = @week_start + 6.days
    end

    def current_user
      # TODO: Replace with actual current_user from authentication
      # For now, return the first property manager
      @current_user ||= User.role_property_manager.first
    end
  end
end
