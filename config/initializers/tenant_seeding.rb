Rails.application.config.to_prepare do
  domains = ENV["DOMAINS"]&.split(/,\s*/)
  TenantSeeder.seed(domains) if domains.present?
end
