class Tenant < ApplicationRecord
  # A uniqueness validation on domain to mirror the database index
  validates :domain, presence: true, uniqueness: true
  validates :name, presence: true
end
