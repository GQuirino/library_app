FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { Faker::Internet.password(min_length: 8) }
    name { Faker::Name.name }
    birthdate { Faker::Date.between(from: '1950-01-01', to: Date.today - 16.years) }
    address { { street: Faker::Address.street_name, city: Faker::Address.city, zip: Faker::Address.zip_code, state: Faker::Address.state } }
    phone_number { Faker::PhoneNumber.phone_number }

    trait :librarian do
      role { :librarian }
    end

    trait :member do
      role { :member }
    end
  end
end
