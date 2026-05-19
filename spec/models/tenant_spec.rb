require 'rails_helper'

RSpec.describe Tenant, type: :model do
  it "is invalid without a domain" do
    tenant = build(:tenant, domain: nil)
    expect(tenant).not_to be_valid
  end

  it "is invalid without a name" do
    tenant = build(:tenant, name: nil)
    expect(tenant).not_to be_valid
  end

  it "is invalid with a duplicate domain" do
    create(:tenant, domain: "cdtaylor.dev")
    duplicate = build(:tenant, domain: "cdtaylor.dev")
    expect(duplicate).not_to be_valid
  end
end
