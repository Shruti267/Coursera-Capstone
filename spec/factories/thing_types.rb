FactoryGirl.define do
  factory :thing_type do
    after(:build) do |link|
      link.type=build(:type) unless link.type
    end
  end
end
