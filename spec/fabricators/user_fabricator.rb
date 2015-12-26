Fabricator(:user) do
  user_id { Fabricate.sequence(:user_id) { |i| "U#{i}" } }
  user_name { Faker::Internet.user_name }
  team { Team.first || Fabricate(:team) }
end
