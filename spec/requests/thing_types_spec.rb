require 'rails_helper'
require 'pry'

RSpec.describe "ThingTypes", type: :request do
  include_context "db_cleanup_each"
  #originator becomes organizer after creation
  let(:thing_originator) { apply_originator(signup(FactoryGirl.attributes_for(:user)), Thing) }
  let(:type_originator) { apply_originator(signup(FactoryGirl.attributes_for(:user)), Type) }

  describe "manage thing/type relationships" do
    #let!(:user) { login originator }
    context "valid thing and type" do
      let(:thing) { create_resource(things_path, :thing) }
      let(:type) { create_resource(types_path, :type) }
      let(:thing_type_props) {
        FactoryGirl.attributes_for(:thing_type, :type_id=>type["id"])
      }

      before(:each) do
        login type_originator
        type
        logout
        login thing_originator
        thing
      end

      it "can associate type with thing" do
        # associated the Type to the Thing
        jpost thing_thing_types_path(thing["id"]), thing_type_props
        expect(response).to have_http_status(:no_content)
        # get ThingTypes for Thing and verify associated with Type
        jget thing_thing_types_path(thing["id"])
        expect(response).to have_http_status(:ok)
        #puts response.body
        payload=parsed_body
        expect(payload.size).to eq(1)
        expect(payload[0]).to include("thing_id"=>thing["id"])
        expect(payload[0]).to include("thing_name"=>thing["name"])
        expect(payload[0]).to include("type_id"=>type["id"])
        expect(payload[0]).to include("type_name"=>type["name"])
        expect(payload[0]).to include("creator_id")
        expect(payload[0]).to include("is_vip_pass_required"=>false)
      end

      it "must have type" do
        jpost thing_thing_types_path(thing["id"]),
              thing_type_props.except(:type_id)
        expect(response).to have_http_status(:bad_request)
        payload=parsed_body
        expect(payload).to include("errors")
        expect(payload["errors"]["full_messages"]).to include(/param/,/missing/)
      end
    end
  end

  shared_examples "can get links for Thing" do
    it do
      jget thing_thing_types_path(linked_thing_id)
      #pp parsed_body
      expect(response).to have_http_status(:ok)
      expect(parsed_body.size).to eq(linked_type_ids.count)
      expect(parsed_body[0]).to include("thing_name"=>linked_thing["name"])
      expect(parsed_body[0]).to include("type_name")
    end
  end

  shared_examples "cannot get links for Thing" do |status=:unauthorized|
    it do
      jget thing_thing_types_path(linked_thing_id)
      #pp parsed_body
      expect(response).to have_http_status(status)
    end
  end

  shared_examples "can get links for Type" do
    it do
      jget type_thing_types_path(linked_type_id)
      #pp parsed_body
      expect(response).to have_http_status(:ok)
      expect(parsed_body.size).to eq(1)
      expect(parsed_body[0]).to include("thing_name"=>linked_thing["name"])
      expect(parsed_body[0]).to include("type_name")
    end
  end

  shared_examples "cannot get links for Type" do |status=:unauthorized|
    it do
      jget type_thing_types_path(linked_type_id)
      #pp parsed_body
      expect(response).to have_http_status(status)
    end
  end

  shared_examples "get linkables" do |count, user_roles=[]|
    it "return linkable things" do
      jget type_linkable_things_path(linked_type_ids[0])
      #pp parsed_body
      expect(response).to have_http_status(:ok)
      expect(parsed_body.size).to eq(count)
      if (count > 0)
        parsed_body.each do |thing|
          expect(thing["id"]).to be_in(unlinked_thing_ids)
          expect(thing).to include("description")
          expect(thing).to include("notes")
          expect(thing).to include("user_roles")
          expect(thing["user_roles"]).to include(*user_roles)
        end
      end
    end
  end

  shared_examples "can create link" do
    it "link from Thing to Type" do
      jpost thing_thing_types_path(linked_thing_id), thing_type_props
      expect(response).to have_http_status(:no_content)
      jget thing_thing_types_path(linked_thing_id)
      expect(parsed_body.size).to eq(linked_type_ids.count+1)
    end

    it "link from Type to Thing" do
      jpost type_thing_types_path(thing_type_props[:type_id]),
            thing_type_props.merge(:thing_id=>linked_thing_id)
      expect(response).to have_http_status(:no_content)
      jget thing_thing_types_path(linked_thing_id)
      expect(parsed_body.size).to eq(linked_type_ids.count+1)
    end

    it "bad request when link to unknown Type" do
      jpost thing_thing_types_path(linked_thing_id),
            thing_type_props.merge(:type_id=>99999)
      expect(response).to have_http_status(:bad_request)
    end

    it "bad request when link to unknown Thing" do
      jpost type_thing_types_path(thing_type_props[:type_id]),
            thing_type_props.merge(:thing_id=>99999)
      expect(response).to have_http_status(:bad_request)
    end
  end

  shared_examples "can update link" do
    it do
      jput thing_thing_type_path(thing_type["thing_id"], thing_type["id"]),
           thing_type.merge("is_vip_pass_required"=>true)
      expect(response).to have_http_status(:no_content)
    end
  end

  shared_examples "can delete link" do
    it do
      jdelete thing_thing_type_path(thing_type["thing_id"], thing_type["id"])
      expect(response).to have_http_status(:no_content)
    end
  end

  shared_examples "cannot create link" do |status=:unauthorized|
    it do
      jpost thing_thing_types_path(linked_thing_id), thing_type_props
      expect(response).to have_http_status(status)
    end
  end

  shared_examples "cannot update link" do |status=:unauthorized|
    it do
      jput thing_thing_type_path(thing_type["thing_id"], thing_type["id"]),
           thing_type.merge("is_vip_pass_required"=>true)
      expect(response).to have_http_status(status)
    end
  end

  shared_examples "cannot delete link" do |status=:unauthorized|
    it do
      jdelete thing_thing_type_path(thing_type["thing_id"], thing_type["id"])
      expect(response).to have_http_status(status)
    end
  end

  describe "ThingType Authn policies" do
    let(:account)         { signup FactoryGirl.attributes_for(:user) }
    let(:thing_resources) { 3.times.map { create_resource(things_path, :thing, :created) } }
    let(:type_resources) { 4.times.map { create_resource(types_path, :type, :created) } }
    let(:things)          { thing_resources.map {|t| Thing.find(t["id"]) } }
    let(:linked_thing)    { things[0] }
    let(:linked_thing_id) { linked_thing.id }
    let(:linked_type_ids)  { (0..2).map {|idx| type_resources[idx]["id"] } }
    let(:unlinked_thing_ids){ (1..2).map {|idx| thing_resources[idx]["id"] } }
    let(:linked_type_id)   { type_resources[0]["id"] }
    let(:orphan_type_id)   { type_resources[3]["id"] }     #unlinked type to link to thing
    let(:thing_type_props) { { :type_id=>orphan_type_id } } #payload required to link type
    let(:thing_type)       { #return existing thing so we can modify
      jget thing_thing_types_path(linked_thing_id)
      expect(response).to have_http_status(:ok)
      parsed_body[0]
    }
    before(:each) do
      login type_originator
      type_resources
      logout
      login thing_originator
      thing_resources
      linked_type_ids.each do |type_id| #link thing and types, leave orphans
        jpost thing_thing_types_path(linked_thing_id), {:type_id=>type_id}
        expect(response).to have_http_status(:no_content)
      end
    end

    context "user is anonymous" do
      before(:each) {
        thing_type
        logout
      }
      it_should_behave_like "cannot get links for Thing", :unauthorized
      it_should_behave_like "cannot get links for Type", :unauthorized
      it_should_behave_like "cannot create link", :unauthorized
      it_should_behave_like "cannot update link", :unauthorized
      it_should_behave_like "cannot delete link", :unauthorized
    end

    context "user is authenticated" do
      before(:each) { login account }
      it_should_behave_like "can get links for Thing"
      it_should_behave_like "can get links for Type"
      it_should_behave_like "cannot create link", :forbidden
      it_should_behave_like "cannot update link", :forbidden
      it_should_behave_like "cannot delete link", :forbidden
    end

    context "user is member" do
      before(:each) do
        login apply_member(account, things)
      end
      it_should_behave_like "can get links for Thing"
      it_should_behave_like "can get links for Type"
      it_should_behave_like "cannot create link", :forbidden
      it_should_behave_like "cannot update link", :forbidden
      it_should_behave_like "cannot delete link", :forbidden
    end

    context "user is organizer" do
      it_should_behave_like "can get links for Thing"
      it_should_behave_like "can get links for Type"
      it_should_behave_like "can create link"
      it_should_behave_like "can update link"
      it_should_behave_like "can delete link"
    end

    context "user is admin" do
      before(:each) { login apply_admin(account) }
      it_should_behave_like "can get links for Thing"
      it_should_behave_like "can get links for Type"
      it_should_behave_like "cannot create link", :forbidden
      it_should_behave_like "cannot update link", :forbidden
      it_should_behave_like "can delete link"
    end
  end
end
