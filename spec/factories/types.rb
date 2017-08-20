FactoryGirl.define do
  factory :type do
    name { Faker::Commerce.product_name }
    sequence(:notes) {|n| n%2==0 ? nil : Faker::Lorem.paragraphs.join}
    creator_id 1

    trait :with_notes do
      notes       { Faker::Lorem.paragraphs.join }
    end

    trait :with_roles do
      after(:create) do |type|
        Role.create(:role_name=>Role::ORGANIZER,
                    :mname=>Type.name,
                    :mid=>type.id,
                    :user_id=>type.creator_id)
      end
    end
  end
end
