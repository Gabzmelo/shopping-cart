FactoryBot.define do
  factory :cart do
    total_price { 0.0 }
    last_interaction_at { Time.current }

    factory :abandoned_cart do
      abandoned_at { 3.hours.ago }
    end

    factory :old_abandoned_cart do
      abandoned_at { 8.days.ago }
    end
  end
end
