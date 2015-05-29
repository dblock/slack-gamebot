class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :user_name, type: String
  field :wins, type: Integer, default: 0
  field :losses, type: Integer, default: 0
  field :elo, type: Integer, default: 0
  field :tau, type: Float, default: 0

  index({ user_id: 1, team_id: 1 }, unique: true, name: 'user_team_index')

  def slack_mention
    "<@#{user_id}>"
  end

  def self.find_by_slack_mention(user_name)
    User.where(user_name =~ /^<@(.*)>$/ ? { user_id: Regexp.last_match[1] } : { user_name: Regexp.new("^#{user_name}$", 'i') }).first
  end

  # Find an existing record, update the username if necessary, otherwise create a user record.
  def self.find_create_or_update_by_slack_id!(slack_id)
    instance = User.where(user_id: slack_id).first
    instance_info = Hashie::Mash.new(Slack.users_info(user: slack_id)).user
    instance.update_attributes!(user_name: instance_info.name) if instance && instance.user_name != instance_info.name
    instance ||= User.create!(user_id: slack_id, user_name: instance_info.name)
    instance
  end

  def self.leaderboard(max = 3)
    players = User.all.any_of({ :wins.gt => 0 }, :losses.gt => 0)
    players = players.limit(max) if max && max > 0
    players = players.desc(:elo).asc(:_id).to_a
    rank = 1
    leaderboard = []
    players.each_with_index do |player, index|
      rank += 1 if index > 0 && players[index - 1].elo != player.elo
      leaderboard << "#{rank}. #{player}"
    end
    leaderboard.any? ? leaderboard.join("\n") : 'No players.'
  end

  def self.reset_all!
    User.all.set(wins: 0, losses: 0, elo: 0, tau: 0)
  end

  def to_s
    "#{user_name}: #{wins} win#{wins != 1 ? 's' : ''}, #{losses} loss#{losses != 1 ? 'es' : ''} (elo: #{elo})"
  end
end
