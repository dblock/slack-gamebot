Fabricator(:team) do
  token { Fabricate.sequence(:team_token) { |i| "abc-#{i}" } }
  team_id { Fabricate.sequence(:team_id) { |i| "T#{i}" } }
  activated_user_id { Fabricate.sequence(:activated_user_id) { |i| "U#{i}" } }
  game { Game.first || Fabricate(:game) }
  name { Faker::Lorem.word }
  api { true }
end
