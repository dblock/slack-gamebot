class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :user_name, type: String
  field :wins, type: Integer, default: 0
  field :losses, type: Integer, default: 0
  field :elo, type: Integer, default: 0
  field :tau, type: Float, default: 0
  field :rank, type: Integer
  field :is_admin, type: Boolean, default: false

  belongs_to :team, index: true
  validates_presence_of :team

  index({ user_id: 1, team_id: 1 }, unique: true)
  index(user_name: 1, team_id: 1)
  index(wins: 1, team_id: 1)
  index(losses: 1, team_id: 1)
  index(elo: 1, team_id: 1)

  after_save :rank!

  SORT_ORDERS = ['elo', '-elo', 'created_at', '-created_at', 'wins', '-wins', 'losses', '-losses', 'user_name', '-user_name', 'rank', '-rank']

  scope :ranked, -> { where(:rank.ne => nil) }
  scope :admins, -> { where(is_admin: true) }

  def slack_mention
    "<@#{user_id}>"
  end

  def self.find_by_slack_mention!(team, user_name)
    query = user_name =~ /^<@(.*)>$/ ? { user_id: Regexp.last_match[1] } : { user_name: Regexp.new("^#{user_name}$", 'i') }
    user = User.where(query.merge(team: team)).first
    fail ArgumentError, "I don't know who #{user_name} is! Ask them to _#{SlackRubyBot.config.user} register_." unless user
    user
  end

  def self.find_many_by_slack_mention!(team, user_names)
    user_names.map { |user| find_by_slack_mention!(team, user) }
  end

  # Find an existing record, update the username if necessary, otherwise create a user record.
  def self.find_create_or_update_by_slack_id!(client, slack_id)
    instance = User.where(team: client.team, user_id: slack_id).first
    instance_info = Hashie::Mash.new(client.web_client.users_info(user: slack_id)).user
    instance.update_attributes!(user_name: instance_info.name) if instance && instance.user_name != instance_info.name
    instance ||= User.create!(team: client.team, user_id: slack_id, user_name: instance_info.name)
    instance.update_attributes!(is_admin: true) unless instance.is_admin? || client.team.admins.count > 0
    instance
  end

  def self.reset_all!(team)
    User.where(team: team).set(wins: 0, losses: 0, elo: 0, tau: 0, rank: nil)
  end

  def to_s
    "#{user_name}: #{wins} win#{wins != 1 ? 's' : ''}, #{losses} loss#{losses != 1 ? 'es' : ''} (elo: #{elo})"
  end

  def rank!
    return unless elo_changed?
    User.rank!(team)
    reload.rank
  end

  def self.rank!(team)
    rank = 1
    players = any_of({ :wins.gt => 0 }, :losses.gt => 0).where(team: team).desc(:elo).asc(:wins)
    players.each_with_index do |player, index|
      rank += 1 if index > 0 && players[index - 1].elo != player.elo
      player.update_attributes!(rank: rank) unless rank == player.rank
    end
  end

  def self.rank_section(users)
    ranks = users.map(&:rank)
    where(:rank.gte => ranks.min, :rank.lte => ranks.max).asc(:rank).asc(:wins)
  end
end
