require 'rails_helper'

RSpec.describe Type, type: :model do
  include_context "db_cleanup_each"

  context "valid type" do
    let(:type) { FactoryGirl.create(:type) }

    it "creates new instance" do
      db_type=Type.find(type.id)
      expect(db_type.name).to eq(type.name)
    end
  end

  context "invalid type" do
    let(:type) { FactoryGirl.build(:type, :name=>nil) }

    it "provides error messages" do
      expect(type.validate).to be false
      expect(type.errors.messages).to include(:name=>["can't be blank"])
    end
  end
end
