FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Produto #{n}" }
    price { 9.99 }
  end
end
