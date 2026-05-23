require 'rails_helper'

RSpec.describe TenantSeeder do
  it "with no domains, does nothing" do
    expect { TenantSeeder.seed([]) }.not_to change(Tenant, :count)
  end

  it "with one domain, creates one tenant" do
    TenantSeeder.seed([ "example.com" ])
    expect(Tenant.find_by(domain: "example.com")).to be_present
  end

  it "with multiple domains, creates all of them" do
    TenantSeeder.seed([ "ex1.com", "ex2.com" ])
    expect(Tenant.find_by(domain: "ex1.com")).to be_present
    expect(Tenant.find_by(domain: "ex2.com")).to be_present
  end

  it "with duplicate domains, creates only one tenant" do
    expect { TenantSeeder.seed([ "example.com", "example.com" ]) }
      .to change(Tenant, :count).by(1)
  end

  it "when a tenant already exists, does not create a duplicate" do
    create(:tenant, domain: "example.com")
    TenantSeeder.seed([ "example.com" ])
    expect(Tenant.where(domain: "example.com").count).to eq(1)
  end
end
