FactoryBot.define do
  factory :reservation do
    association :book_copy
    association :user
    return_date { Date.today + 7.days }
    returned_at { Date.today }

    trait :ended_with_overdue_date do
      return_date { Date.today - 3.days }
      returned_at { nil }
    end

    trait :returned do
      return_date { Date.today + 3.days }
      returned_at { Date.today }
    end

    trait :open do
      return_date { Date.today + 7.days }
      returned_at { nil }
    end

    trait :overdue do
      return_date { Date.today - 1.day }
      returned_at { Date.today }
    end
  end
end
