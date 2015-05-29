Fabricator(:user) do
  user_id { Fabricate.sequence(:user_id) { |i| "U#{i}" } }
  user_name { Faker::Name.first_name }
end
