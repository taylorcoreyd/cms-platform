namespace :tenant do
  desc "Seed tenants from TENANT_DOMAINS environment variable"
  task seed: :environment do
    domains = ENV.fetch("DOMAINS", "").split(/,\s*/).reject(&:blank?)
    TenantSeeder.seed(domains)
  end
end
