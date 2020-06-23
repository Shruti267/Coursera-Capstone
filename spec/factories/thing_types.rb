FactoryGirl.define do
  factory :thing_type do
    creator_id 1
    after(:build) do |link|
      link.type=build(:type) unless link.type
    end
  end
end
