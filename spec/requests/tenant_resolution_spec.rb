require "rails_helper"

RSpec.describe "Tenant resolution", type: :request do
  let!(:dev_tenant)       { create(:tenant, domain: "cdtaylor.dev", name: "Dev") }
  let!(:photo_tenant)     { create(:tenant, domain: "cdtaylor.photography", name: "Photography") }
  let!(:localhost_tenant) { create(:tenant, domain: "localhost", name: "Local") }

  describe "known host" do
    it "serves cdtaylor.dev without error" do
      get root_path, headers: { "HOST" => "cdtaylor.dev" }
      expect(response).not_to have_http_status(:not_found)
    end

    it "serves cdtaylor.photography without error" do
      get root_path, headers: { "HOST" => "cdtaylor.photography" }
      expect(response).not_to have_http_status(:not_found)
    end

    it "serves localhost without error" do
      get root_path, headers: { "HOST" => "localhost" }
      expect(response).not_to have_http_status(:not_found)
    end
  end

  describe "unknown host" do
    it "returns 404" do
      get root_path, headers: { "HOST" => "unknown.example.com" }
      expect(response).to have_http_status(:not_found)
    end
  end
end
