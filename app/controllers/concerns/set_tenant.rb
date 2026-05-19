module SetTenant
  extend ActiveSupport::Concern

  included do
    before_action :set_tenant
  end

  def set_tenant
    domain = request.host

    Current.tenant = if Rails.env.development? && domain.in?([ "localhost", "127.0.0.1" ])
      Tenant.find_by!(domain: "localhost")
    else
      Tenant.find_by!(domain: domain)
    end
  rescue ActiveRecord::RecordNotFound
    # Unknown hosts should fail closed. Seed a localhost tenant for development.
    raise ActionController::RoutingError, "Not Found"
  end
end
