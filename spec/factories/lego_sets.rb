# spec/factories/lego_sets.rb
FactoryBot.define do
  factory :lego_set do
    title { Faker::Lorem.word }
    number { Faker::Number.number(10) }
  end
end
