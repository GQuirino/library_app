FactoryBot.define do
  factory :book_copy do
    association :book
    book_serial_number { Faker::Alphanumeric.unique.alphanumeric(number: 10).upcase }
    available { true }

    trait :unavailable do
      available { false }
    end

    trait :available do
      available { true }
    end

    trait :with_reservations do
      available { true }

      after(:create) do |book_copy|
        create_list(:reservation, 2, :open, book_copy: book_copy)
      end
    end

    trait :with_all_copies_reserved do
      available { false }

      after(:create) do |book_copy|
        create(:reservation, :open, book_copy: book_copy)
      end
    end
  end
end
