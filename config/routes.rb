Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Property Managers namespace
  namespace :property_managers do
    resource :calendar, only: [ :show, :create ]
  end
end
