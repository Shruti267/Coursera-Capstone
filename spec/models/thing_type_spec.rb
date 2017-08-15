require 'rails_helper'

RSpec.describe ThingType, type: :model do
  include_context "db_cleanup_each"

  context "valid thing" do
    let(:thing) { FactoryGirl.build(:thing) }

    it "build type for thing and save" do
      tt = FactoryGirl.build(:thing_type, :thing=>thing)
      tt.save!
      expect(thing).to be_persisted
      expect(tt).to be_persisted
      expect(tt.type).to_not be_nil
      expect(tt.type).to be_persisted
    end

    it "relate multiple types" do
      thing.thing_types << FactoryGirl.build_list(:thing_type, 3, :thing=>thing)
      thing.save!
      expect(Thing.find(thing.id).thing_types.size).to eq(3)

      thing.thing_types.each do |ti|
        expect(ti.type.things.first).to eql(thing) #same instance
      end
    end

    it "build types using factory" do
      thing=FactoryGirl.create(:thing, :with_type, :type_count=>2)
      expect(Thing.find(thing.id).thing_types.size).to eq(2)
      thing.thing_types.each do |ti|
        expect(ti.type.things.first).to eql(thing) #same instance
      end
    end
  end

  context "related thing and type" do
    let(:thing) { FactoryGirl.create(:thing, :with_type) }
    let(:thing_type) { thing.thing_types.first }
    before(:each) do
      #sanity check that objects and relationships are in place
      expect(ThingType.where(:id=>thing_type.id).exists?).to be true
      expect(Type.where(:id=>thing_type.type_id).exists?).to be true
      expect(Thing.where(:id=>thing_type.thing_id).exists?).to be true
    end
    after(:each)  do
      #we always expect the thing_type to be deleted during each test
      expect(ThingType.where(:id=>thing_type.id).exists?).to be false
    end

    it "deletes link but not type when thing removed" do
      thing.destroy
      expect(Type.where(:id=>thing_type.type_id).exists?).to be true
      expect(Thing.where(:id=>thing_type.thing_id).exists?).to be false
    end

    it "deletes link but not thing when type removed" do
      thing_type.type.destroy
      expect(Type.where(:id=>thing_type.type_id).exists?).to be false
      expect(Thing.where(:id=>thing_type.thing_id).exists?).to be true
    end
  end
end
