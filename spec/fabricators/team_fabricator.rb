Fabricator(:team) do
  token { Fabricate.sequence(:team_token) { |i| "abc-#{i}" } }
  secret { Fabricate.sequence(:team_secret) { |i| "secret#{i}" } }
  team_id { Fabricate.sequence(:team_id) { |i| "T#{i}" } }
  name { Faker::Name.first_name }
end
