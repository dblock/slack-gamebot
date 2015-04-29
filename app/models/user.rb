class User
  include Mongoid::Document

  field :team_id, type: String
  field :user_id, type: String
  field :user_name

  index({ user_id: 1, team_id: 1 }, unique: true, name: 'user_team_index')
end
