# This model provides a tenant attribute available for the duration of each request
class Current < ActiveSupport::CurrentAttributes
  attribute :tenant
end
