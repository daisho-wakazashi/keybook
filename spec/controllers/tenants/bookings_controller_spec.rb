require 'rails_helper'

RSpec.describe Tenants::BookingsController, type: :controller do
  let(:tenant) { create(:user, :tenant) }
  let(:property_manager) { create(:user, :property_manager) }
  let(:availability) { create(:availability, user: property_manager) }

  before do
    # Stub current_user to return our test tenant
    allow(controller).to receive(:current_user).and_return(tenant)
  end

  describe 'GET #show' do
    let(:booking) { create(:booking, booker: tenant, availability: availability) }

    it 'returns http success' do
      get :show, params: { id: property_manager.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    let(:service_double) { instance_double(CreateBookingForAvailability) }

    before do
      allow(CreateBookingForAvailability).to receive(:perform).and_return(service_double)
    end

    context 'when service succeeds' do
      before do
        allow(service_double).to receive(:success?).and_return(true)
      end

      it 'calls the service with current_user and availability_id' do
        expect(CreateBookingForAvailability).to receive(:perform).with(tenant, availability.id.to_s)
        post :create, params: { id: property_manager.id, availability_id: availability.id }
      end

      it 'returns created status' do
        post :create, params: { id: property_manager.id, availability_id: availability.id }
        expect(response).to have_http_status(:created)
      end

      it 'sets a success flash message' do
        post :create, params: { id: property_manager.id, availability_id: availability.id }
        expect(flash[:notice]).to match(/created successfully/i)
      end

      it 'renders the create template' do
        post :create, params: { id: property_manager.id, availability_id: availability.id }
        expect(response).to render_template(:create)
      end
    end

    context 'when service fails' do
      let(:error_messages) { instance_double(ActiveModel::Errors) }

      before do
        allow(service_double).to receive(:success?).and_return(false)
        allow(service_double).to receive(:errors).and_return(error_messages)
        allow(error_messages).to receive(:full_messages).and_return([ "Availability not found" ])
      end

      it 'calls the service with current_user and availability_id' do
        expect(CreateBookingForAvailability).to receive(:perform).with(tenant, availability.id.to_s)
        post :create, params: { id: property_manager.id, availability_id: availability.id }
      end

      it 'returns unprocessable_entity status' do
        post :create, params: { id: property_manager.id, availability_id: availability.id }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'sets an error flash message' do
        post :create, params: { id: property_manager.id, availability_id: availability.id }
        expect(flash[:alert]).to match(/failed/i)
      end

      it 'includes the error messages in the flash' do
        post :create, params: { id: property_manager.id, availability_id: availability.id }
        expect(flash[:alert]).to include("Availability not found")
      end

      it 'renders the create template' do
        post :create, params: { id: property_manager.id, availability_id: availability.id }
        expect(response).to render_template(:create)
      end
    end
  end
end
