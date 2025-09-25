FactoryBot.define do
  factory :reservation do
    association :book_copy
    association :user
    return_date { Date.today + 7.days }
    returned_at { Date.today }

    trait :active_with_overdue_date do
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

    # Skip validations when using this trait to allow creating reservations with past return dates
    after(:build) do |reservation|
      def reservation.valid?(*args)
        true
      end
    end
  end
end
