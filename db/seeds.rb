# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Seeding Tenants
# We ordinarily define Tenants through the environment variable DOMAINS
# domains variable will try to get domains from the environment variable DOMAINS if provided
# otherwise if development, seed with "localhost"
# if not development, then a string of an empty list of domains
# Then parse the list, strip it, and reject blanks for good measure.
# Then seed!
domains = ENV.fetch("DOMAINS", Rails.env.development? ? "localhost" : "")
            .split(/,\s*/)
            .map(&:strip)
            .reject(&:blank?)
TenantSeeder.seed(domains)
