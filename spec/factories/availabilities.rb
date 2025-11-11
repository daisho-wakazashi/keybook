FactoryBot.define do
  factory :availability do
    user
    start_time { 1.day.from_now.utc.change(hour: 9, min: 0) }
    end_time { 1.day.from_now.utc.change(hour: 10, min: 0) }

    trait :morning do
      start_time { 1.day.from_now.utc.change(hour: 9, min: 0) }
      end_time { 1.day.from_now.utc.change(hour: 12, min: 0) }
    end

    trait :afternoon do
      start_time { 1.day.from_now.utc.change(hour: 13, min: 0) }
      end_time { 1.day.from_now.utc.change(hour: 17, min: 0) }
    end

    trait :evening do
      start_time { 1.day.from_now.utc.change(hour: 18, min: 0) }
      end_time { 1.day.from_now.utc.change(hour: 21, min: 0) }
    end

    trait :next_week do
      start_time { 7.days.from_now.utc.change(hour: 9, min: 0) }
      end_time { 7.days.from_now.utc.change(hour: 10, min: 0) }
    end
  end
end
