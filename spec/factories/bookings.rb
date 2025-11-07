FactoryBot.define do
  factory :booking do
    association :booker, factory: [ :user, :tenant ]
    association :availability
  end
end
