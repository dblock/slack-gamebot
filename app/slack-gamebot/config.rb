module SlackGamebot
  module Config
    extend self

    attr_accessor :token
    attr_accessor :url
    attr_accessor :user
    attr_accessor :user_id
    attr_accessor :team
    attr_accessor :team_id
  end
end
