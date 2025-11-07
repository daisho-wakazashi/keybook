module Tenants
  class BookingsController < ApplicationController
    def show
      # TODO: Implement show action
    end

    def create
      booking_service = CreateBookingForAvailability.perform(current_user, params[:availability_id])

      if booking_service.success?
        flash.now[:notice] = "Booking created successfully"
        render :create, status: :created
      else
        flash.now[:alert] = "Booking failed: #{booking_service.errors.full_messages.join(', ')}"
        render :create, status: :unprocessable_entity
      end
    end

    private

    def current_user
      # TODO: Replace with actual current_user from authentication
      # For now, return the first tenant
      @current_user ||= User.role_tenant.first
    end
  end
end
