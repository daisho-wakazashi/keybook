module PropertyManagers
  class CalendarsController < ApplicationController
    def show
      set_dates_and_availabilities
    end

    def create
      creation_service = CreateAvailabilitiesForUser.perform(current_user, params[:availabilities])

      # reload for Turbo stream
      set_dates_and_availabilities

      if creation_service.success?
        flash.now[:notice] = t("property_managers.calendar.created")
        render :create, status: :created
      else
        flash.now[:alert] = t("property_managers.calendar.creation_errors", errors: creation_service.errors_full_messages.join(", "))
        render :create, status: :unprocessable_entity
      end
    end

    private

    def set_dates_and_availabilities
      # Unnecessary before actions can lead to weirdness
      @date = params[:date] ? Date.parse(params[:date]) : Date.current
      @week_start = @date.beginning_of_week(:sunday)
      @week_end = @week_start + 6.days
      @availabilities = current_user.availabilities
                                    .where(start_time: @week_start.beginning_of_day..@week_end.end_of_day)
                                    .order(:start_time)
    end

    def current_user
      # TODO: Replace with actual current_user from authentication
      # For now, return the first property manager
      @current_user ||= User.role_property_manager.first
    end
  end
end
