FactoryBot.define do
  factory :book do
    title { Faker::Book.title }
    author { Faker::Book.author }
    publisher { Faker::Book.publisher }
    edition { Faker::Lorem.word }
    year { Faker::Date.between(from: '1900-01-01', to: Date.today).year }
  end
end
