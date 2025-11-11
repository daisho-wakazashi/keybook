require 'rails_helper'

RSpec.describe PropertyManagers::CalendarsController, type: :controller do
  let(:property_manager) { create(:user, :property_manager) }

  before do
    # Stub current_user to return our test user
    allow(controller).to receive(:current_user).and_return(property_manager)
  end

  describe 'GET #show' do
    context 'without date parameter' do
      it 'returns http success' do
        get :show
        expect(response).to have_http_status(:success)
      end

      it 'sets the current week as default' do
        travel_to Time.zone.local(2025, 12, 15, 12, 0, 0) do
          get :show
          expect(assigns(:week_start)).to eq(Date.new(2025, 12, 14)) # Sunday
          expect(assigns(:week_end)).to eq(Date.new(2025, 12, 20)) # Saturday
        end
      end

      it 'loads availabilities for the current week' do
        # Create an availability in the current week
        create(:availability,
               user: property_manager,
               start_time: 1.day.from_now.change(hour: 9, min: 0),
               end_time: 1.day.from_now.change(hour: 12, min: 0))

        get :show
        expect(assigns(:availabilities)).to be_present
      end
    end

    context 'with date parameter' do
      let(:specific_date) { Date.new(2025, 12, 15) } # A Monday

      it 'returns http success' do
        get :show, params: { date: specific_date.to_s }
        expect(response).to have_http_status(:success)
      end

      it 'sets the week containing the specified date' do
        get :show, params: { date: specific_date.to_s }

        expected_week_start = specific_date.beginning_of_week(:sunday)
        expect(assigns(:week_start)).to eq(expected_week_start)
        expect(assigns(:week_end)).to eq(expected_week_start + 6.days)
      end

      it 'loads availabilities for the specified week' do
        week_start = specific_date.beginning_of_week(:sunday)

        # Create availabilities in the week
        in_week = create(:availability,
                        user: property_manager,
                        start_time: week_start + 1.day + 9.hours,
                        end_time: week_start + 1.day + 12.hours)

        # Create availability outside the week
        out_of_week = create(:availability,
                            user: property_manager,
                            start_time: week_start + 10.days + 9.hours,
                            end_time: week_start + 10.days + 12.hours)

        get :show, params: { date: specific_date.to_s }

        expect(assigns(:availabilities)).to include(in_week)
        expect(assigns(:availabilities)).not_to include(out_of_week)
      end
    end

    context 'with existing availabilities' do
      it 'orders availabilities by start_time' do
        travel_to Time.zone.local(2025, 12, 15, 12, 0, 0) do
          # Week starts Sunday Dec 14, 2025
          # Create availabilities later in the week (Wed Dec 17 and Thu Dec 18) to ensure they're in the future

          availability1 = create(:availability,
                                user: property_manager,
                                start_time: Time.zone.local(2025, 12, 17, 9, 0, 0),
                                end_time: Time.zone.local(2025, 12, 17, 12, 0, 0))

          availability2 = create(:availability,
                                user: property_manager,
                                start_time: Time.zone.local(2025, 12, 18, 14, 0, 0),
                                end_time: Time.zone.local(2025, 12, 18, 17, 0, 0))

          get :show

          expect(assigns(:availabilities).first).to eq(availability1)
          expect(assigns(:availabilities).second).to eq(availability2)
        end
      end
    end
  end

  describe 'POST #create' do
    let(:availabilities_json) do
      [
        {
          start_time: 1.day.from_now.change(hour: 9, min: 0).iso8601,
          end_time: 1.day.from_now.change(hour: 12, min: 0).iso8601
        }
      ].to_json
    end

    # All create action requests should use Turbo Stream format
    let(:request_params) { { availabilities: availabilities_json, format: :turbo_stream } }

    context 'when service succeeds (zero errors)' do
      let(:successful_service) do
        instance_double(CreateAvailabilitiesForUser,
                       success?: true,
                       errors_full_messages: [])
      end

      before do
        allow(CreateAvailabilitiesForUser).to receive(:perform)
          .with(property_manager, availabilities_json)
          .and_return(successful_service)
      end

      it 'renders the create template' do
        post :create, params: request_params

        expect(response).to render_template(:create)
      end

      it 'sets a success notice in flash.now' do
        post :create, params: request_params

        expect(flash.now[:notice]).to eq(I18n.t('property_managers.calendar.created'))
      end

      it 'does not set an alert' do
        post :create, params: request_params

        expect(flash.now[:alert]).to be_nil
      end

      it 'calls the service with correct parameters' do
        expect(CreateAvailabilitiesForUser).to receive(:perform)
          .with(property_manager, availabilities_json)
          .and_return(successful_service)

        post :create, params: request_params
      end

      it 'returns a created status' do
        post :create, params: request_params

        expect(response).to have_http_status(:created)
      end

      it 'loads availabilities for the current week' do
        post :create, params: request_params

        expect(assigns(:availabilities)).not_to be_nil
      end
    end

    context 'when service fails (with errors)' do
      let(:failed_service) do
        instance_double(CreateAvailabilitiesForUser,
                       success?: false,
                       errors_full_messages: [ 'End time must be after start time' ])
      end

      before do
        allow(CreateAvailabilitiesForUser).to receive(:perform)
          .with(property_manager, availabilities_json)
          .and_return(failed_service)
      end

      it 'returns unprocessable entity status' do
        post :create, params: request_params

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'renders the create template' do
        post :create, params: request_params

        expect(response).to render_template(:create)
      end

      it 'sets an error alert with error messages in flash.now' do
        post :create, params: request_params

        expected_message = I18n.t('property_managers.calendar.creation_errors',
                                   errors: 'End time must be after start time')
        expect(flash.now[:alert]).to eq(expected_message)
      end

      it 'does not set a notice' do
        post :create, params: request_params

        expect(flash.now[:notice]).to be_nil
      end

      it 'calls the service with correct parameters' do
        expect(CreateAvailabilitiesForUser).to receive(:perform)
          .with(property_manager, availabilities_json)
          .and_return(failed_service)

        post :create, params: request_params
      end

      it 'loads availabilities for the current week' do
        post :create, params: request_params

        expect(assigns(:availabilities)).not_to be_nil
      end
    end

    context 'when service fails with multiple errors' do
      let(:error_messages) do
        [
          'End time must be after start time',
          'Start time cannot be in the past',
          'Availability overlaps with existing availability'
        ]
      end
      let(:failed_service) do
        instance_double(CreateAvailabilitiesForUser,
                       success?: false,
                       errors_full_messages: error_messages)
      end

      before do
        allow(CreateAvailabilitiesForUser).to receive(:perform)
          .with(property_manager, availabilities_json)
          .and_return(failed_service)
      end

      it 'includes all error messages in the alert' do
        post :create, params: request_params

        expected_message = I18n.t('property_managers.calendar.creation_errors',
                                   errors: error_messages.join(', '))
        expect(flash.now[:alert]).to eq(expected_message)
      end

      it 'returns unprocessable entity status' do
        post :create, params: request_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with date parameter' do
      let(:specific_date) { Date.new(2025, 12, 15) }
      let(:successful_service) do
        instance_double(CreateAvailabilitiesForUser,
                       success?: true,
                       errors_full_messages: [])
      end

      before do
        allow(CreateAvailabilitiesForUser).to receive(:perform)
          .and_return(successful_service)
      end

      it 'renders the create template on success' do
        post :create, params: request_params.merge(date: specific_date.to_s)

        expect(response).to render_template(:create)
      end

      it 'returns a created status on success' do
        post :create, params: request_params.merge(date: specific_date.to_s)

        expect(response).to have_http_status(:created)
      end

      it 'renders the create template on failure' do
        failed_service = instance_double(CreateAvailabilitiesForUser,
                                        success?: false,
                                        errors_full_messages: [ 'Some error' ])

        allow(CreateAvailabilitiesForUser).to receive(:perform)
          .and_return(failed_service)

        post :create, params: request_params.merge(date: specific_date.to_s)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:create)
      end

      it 'loads availabilities for the specified week' do
        post :create, params: request_params.merge(date: specific_date.to_s)

        expect(assigns(:availabilities)).not_to be_nil
      end
    end

    context 'when service returns empty errors but success is false' do
      let(:edge_case_service) do
        instance_double(CreateAvailabilitiesForUser,
                       success?: false,
                       errors_full_messages: [])
      end

      before do
        allow(CreateAvailabilitiesForUser).to receive(:perform)
          .and_return(edge_case_service)
      end

      it 'still treats as failure and shows error message' do
        post :create, params: request_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to be_present
      end
    end
  end

  describe 'private methods' do
    describe '#set_date_range' do
      it 'sets date to current date when no parameter provided' do
        travel_to Time.zone.local(2025, 12, 15, 12, 0, 0) do
          get :show
          expect(assigns(:date)).to eq(Date.new(2025, 12, 15))
        end
      end

      it 'parses the date parameter when provided' do
        specific_date = Date.new(2025, 12, 15)
        get :show, params: { date: specific_date.to_s }
        expect(assigns(:date)).to eq(specific_date)
      end

      it 'sets week_start to the Sunday of the week' do
        # December 15, 2025 is a Monday
        # Week should start on Sunday, December 14, 2025
        specific_date = Date.new(2025, 12, 15)
        get :show, params: { date: specific_date.to_s }

        expect(assigns(:week_start)).to eq(Date.new(2025, 12, 14))
        expect(assigns(:week_start).wday).to eq(0) # Sunday
      end

      it 'sets week_end to 6 days after week_start (Saturday)' do
        specific_date = Date.new(2025, 12, 15)
        get :show, params: { date: specific_date.to_s }

        week_start = assigns(:week_start)
        week_end = assigns(:week_end)
        expect(week_end).to eq(week_start + 6.days)
        expect(week_end.wday).to eq(6) # Saturday
      end
    end

    describe '#current_user' do
      it 'returns the first property manager user' do
        # Note: This test verifies the current implementation
        # In production, this should be replaced with actual authentication
        expect(controller.send(:current_user)).to eq(User.role_property_manager.first)
      end

      it 'memoizes the result' do
        user1 = controller.send(:current_user)
        user2 = controller.send(:current_user)

        expect(user1).to be(user2) # Same object instance
      end
    end
  end

  describe 'service interaction patterns' do
    let(:availabilities_json) do
      [ { start_time: 1.day.from_now.iso8601, end_time: 2.days.from_now.iso8601 } ].to_json
    end
    let(:request_params) { { availabilities: availabilities_json, format: :turbo_stream } }

    it 'calls perform on the service class method' do
      successful_service = instance_double(CreateAvailabilitiesForUser,
                                          success?: true,
                                          errors_full_messages: [])

      expect(CreateAvailabilitiesForUser).to receive(:perform).and_return(successful_service)

      post :create, params: request_params
    end

    it 'checks success? on the returned service instance' do
      successful_service = instance_double(CreateAvailabilitiesForUser,
                                          success?: true,
                                          errors_full_messages: [])

      allow(CreateAvailabilitiesForUser).to receive(:perform).and_return(successful_service)

      expect(successful_service).to receive(:success?).and_return(true)

      post :create, params: request_params
    end

    it 'accesses errors_full_messages on the service instance when success? is false' do
      failed_service = instance_double(CreateAvailabilitiesForUser,
                                       success?: false,
                                       errors_full_messages: [ 'Some error' ])

      allow(CreateAvailabilitiesForUser).to receive(:perform).and_return(failed_service)

      expect(failed_service).to receive(:errors_full_messages).and_return([ 'Some error' ])

      post :create, params: request_params
    end
  end
end
