FactoryGirl.define do
  factory :type do
    name { Faker::Commerce.product_name }
    sequence(:notes) {|n| n%5<2 ? nil : Faker::Lorem.paragraphs.join}

    trait :with_fields do
      notes       { Faker::Lorem.paragraphs.join }
    end
  end
end
