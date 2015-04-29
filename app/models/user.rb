class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :user_name, type: String

  index({ user_id: 1, team_id: 1 }, unique: true, name: 'user_team_index')
end
