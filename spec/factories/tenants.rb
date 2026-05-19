FactoryBot.define do
  factory :tenant do
    name { "Test Site" }
    domain { "test.example.com" }
  end
end
