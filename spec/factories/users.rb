FactoryBot.define do
  factory :user do
    first_name { "John" }
    last_name { "Doe" }
    role { :property_manager }

    trait :tenant do
      role { :tenant }
    end

    trait :with_availabilities do
      after(:create) do |user|
        create_list(:availability, 3, user: user)
      end
    end
  end
end
