class TenantSeeder
  def self.seed(domains)
    domains.each do |domain|
      Tenant.find_or_create_by!(domain: domain) do |tenant|
        tenant.name = domain
      end
    end
  end
end
