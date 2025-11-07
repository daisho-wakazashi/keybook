module Tenants
  class BookingsController < ApplicationController
    def show
      set_property_manager_and_availabilities
    end

    def create
      booking_service = CreateBookingForAvailability.perform(current_user, params[:availability_id])

      set_property_manager_and_availabilities

      if booking_service.success?
        flash.now[:notice] = "Booking created successfully"
        render :create, status: :created
      else
        flash.now[:alert] = "Booking failed: #{booking_service.errors.full_messages.join(', ')}"
        render :create, status: :unprocessable_entity
      end
    end

    private

    def set_property_manager_and_availabilities
      @property_manager = User.role_property_manager.find(params[:id])
      @date = params[:date] ? Date.parse(params[:date]) : Date.current
      @week_start = @date.beginning_of_week(:sunday)
      @week_end = @week_start + 6.days
      @availabilities = @property_manager.availabilities
                                        .includes(:booking)
                                        .where(start_time: @week_start.beginning_of_day..@week_end.end_of_day)
                                        .order(:start_time)
                                        puts @availabilities
    end

    def current_user
      # TODO: Replace with actual current_user from authentication
      # For now, return the first tenant
      @current_user ||= User.role_tenant.first
    end
  end
end
