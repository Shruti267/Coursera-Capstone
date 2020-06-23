require 'rails_helper'

RSpec.describe "Types", type: :request do
  include_context "db_cleanup_each"
  #originator becomes organizer after creation
  let(:originator) { apply_originator(signup(FactoryGirl.attributes_for(:user)), Type) }

  context "quick API check" do
    let!(:user) { login originator }

    it_should_behave_like "resource index", :type
    it_should_behave_like "show resource", :type
    it_should_behave_like "create resource", :type
    it_should_behave_like "modifiable resource", :type
  end

  shared_examples "can list" do |status=:unauthorized|
    it "lists with #{status}" do
      jget types_path
      expect(response).to have_http_status(status)
      expect(parsed_body).not_to include("errors")
    end
  end

  shared_examples "cannot list" do |status=:unauthorized|
    it "fails to list with #{status}" do
      jget types_path
      expect(response).to have_http_status(status)
      expect(parsed_body).to include("errors")
    end
  end

  shared_examples "can show" do |status=:unauthorized|
    it "shows with #{status}" do
      jget types_path(type)
      expect(response).to have_http_status(status)
      expect(parsed_body).not_to include("errors")
    end
  end

  shared_examples "cannot show" do |status=:unauthorized|
    it "fails to show with #{status}" do
      jget types_path(type)
      expect(response).to have_http_status(status)
      expect(parsed_body).to include("errors")
    end
  end

  shared_examples "cannot create" do |status=:unauthorized|
    it "fails to create with #{status}" do
      jpost types_path, type_props
      expect(response).to have_http_status(status)
      expect(parsed_body).to include("errors")
    end
  end

  shared_examples "cannot update" do |status=:unauthorized|
    it "fails to update with #{status}" do
      jput type_path(type_id), type_props
      expect(response).to have_http_status(status)
      expect(parsed_body).to include("errors")
    end
  end

  shared_examples "cannot delete" do |status=:unauthorized|
    it "fails to delete with #{status}" do
      jdelete type_path(type_id)
      expect(response).to have_http_status(status)
      expect(parsed_body).to include("errors")
    end
  end

  shared_examples "can create" do |user_roles=[Role::ORGANIZER]|
    it "creates and has user_roles #{user_roles}" do
      jpost types_path, type_props
      expect(response).to have_http_status(:created)
      #pp parsed_body
      payload=parsed_body
      expect(payload).to include("id")
      expect(payload).to include("name"=>type_props[:name])
      expect(payload).to include("notes"=>type_props[:notes])
      expect(payload).to include("user_roles")
      expect(payload["user_roles"]).to include(*user_roles)
    end
    it "reports error for invalid data" do
      jpost types_path, type_props.except(:name)
      expect(response).to have_http_status(:bad_request)
    end
  end

  shared_examples "can update" do
    it "updates instance" do
      jput type_path(type_id), type_props
      expect(response).to have_http_status(:no_content)
    end
    it "reports update error for invalid data" do
      jput type_path(type_id), type_props.merge(:name=>nil)
      expect(response).to have_http_status(:bad_request)
    end
  end

  shared_examples "can delete" do
    it "can delete" do
      jdelete type_path(type_id)
      expect(response).to have_http_status(:no_content)
    end
  end

  shared_examples "all fields present" do |user_roles|
    it "list has all fields with user_roles #{user_roles}" do
      jget types_path
      expect(response).to have_http_status(:ok)
      payload=parsed_body
      expect(payload.size).to_not eq(0)
      payload.each do |r|
        expect(r).to include("id")
        expect(r).to include("name")
        if user_roles.empty?
          expect(r).to_not include("user_roles")
        else
          expect(r).to include("user_roles")
          expect(r["user_roles"].to_a).to include(*user_roles)
        end
      end
    end

    it "get has all fields with user_roles #{user_roles}" do
      jget type_path(type_id)
      expect(response).to have_http_status(:ok)
      #pp parsed_body
      payload=parsed_body
      expect(payload).to include("id"=>type.id)
      expect(payload).to include("name"=>type.name)
      if !type.notes.nil?
        expect(payload).to include("notes"=>type.notes)
      end
      if user_roles.empty?
        expect(payload).to_not include("user_roles")
      else
        expect(payload).to include("user_roles")
        expect(payload["user_roles"].to_a).to include(*user_roles)
      end
    end
  end

  describe "Type authorization" do
    let(:account) { signup FactoryGirl.attributes_for(:user) }
    let(:admin_account) { apply_admin(signup FactoryGirl.attributes_for(:user)) }
    let(:type_props) { FactoryGirl.attributes_for(:type, :with_notes) }
    let(:type_resources) { 3.times.map { create_resource types_path, :type } }
    let(:type_id)  { type_resources[0]["id"] }
    let(:type)     { Type.find(type_id) }
    before(:each) do
      login originator
      type_resources
    end

    context "caller is anonymous" do
      before(:each) do
        logout
      end
      it_should_behave_like "cannot list"
      it_should_behave_like "cannot show"
      it_should_behave_like "cannot create"
      it_should_behave_like "cannot update"
      it_should_behave_like "cannot delete"
    end

    context "caller is authenticated no role" do
      before(:each) do
        login account
      end
      it_should_behave_like "can list", :ok
      it_should_behave_like "can show", :ok
      it_should_behave_like "cannot create", :forbidden
      it_should_behave_like "cannot update", :forbidden
      it_should_behave_like "cannot delete", :forbidden
      it_should_behave_like "all fields present", []
    end

    context "caller is authenticated non-organizer" do
      before(:each) do
        type_resources.each {|t| apply_member(account,Type.find(t["id"])) }
        login account
      end
      it_should_behave_like "can list", :ok
      it_should_behave_like "can show", :ok
      it_should_behave_like "cannot create", :forbidden
      it_should_behave_like "cannot update", :forbidden
      it_should_behave_like "cannot delete", :forbidden
      it_should_behave_like "all fields present", [Role::MEMBER]
    end

    context "caller is authenticated originator" do
      it_should_behave_like "can list", :ok
      it_should_behave_like "can show", :ok
      it_should_behave_like "can create"
      it_should_behave_like "can update"
      it_should_behave_like "can delete"
      it_should_behave_like "all fields present", [Role::ORGANIZER]
    end

    context "caller is admin" do
      before(:each) do
        login admin_account
      end
      it_should_behave_like "can list", :ok
      it_should_behave_like "can show", :ok
      it_should_behave_like "cannot create", :forbidden
      it_should_behave_like "cannot update", :forbidden
      it_should_behave_like "can delete" #, Role::ADMIN
      it_should_behave_like "all fields present", []
    end
  end
end
