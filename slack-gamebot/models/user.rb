class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :user_name, type: String
  field :wins, type: Integer, default: 0
  field :losses, type: Integer, default: 0
  field :ties, type: Integer, default: 0
  field :elo, type: Integer, default: 0
  field :tau, type: Float, default: 0
  field :rank, type: Integer
  field :captain, type: Boolean, default: false
  field :registered, type: Boolean, default: true

  belongs_to :team, index: true
  validates_presence_of :team

  index({ user_id: 1, team_id: 1 }, unique: true)
  index(user_name: 1, team_id: 1)
  index(wins: 1, team_id: 1)
  index(losses: 1, team_id: 1)
  index(ties: 1, team_id: 1)
  index(elo: 1, team_id: 1)

  after_save :rank!

  SORT_ORDERS = ['elo', '-elo', 'created_at', '-created_at', 'wins', '-wins', 'losses', '-losses', 'ties', '-ties', 'user_name', '-user_name', 'rank', '-rank']

  scope :ranked, -> { where(:rank.ne => nil) }
  scope :captains, -> { where(captain: true) }

  def slack_mention
    "<@#{user_id}>"
  end

  def self.find_by_slack_mention!(team, user_name)
    query = user_name =~ /^<@(.*)>$/ ? { user_id: Regexp.last_match[1] } : { user_name: Regexp.new("^#{user_name}$", 'i') }
    user = User.where(query.merge(team: team)).first
    fail SlackGamebot::Error, "I don't know who #{user_name} is! Ask them to _register_." unless user && user.registered?
    user
  end

  def self.find_many_by_slack_mention!(team, user_names)
    user_names.map { |user| find_by_slack_mention!(team, user) }
  end

  # Find an existing record, update the username if necessary, otherwise create a user record.
  def self.find_create_or_update_by_slack_id!(client, slack_id)
    instance = User.where(team: client.owner, user_id: slack_id).first
    instance_info = Hashie::Mash.new(client.web_client.users_info(user: slack_id)).user
    instance.update_attributes!(user_name: instance_info.name) if instance && instance.user_name != instance_info.name
    instance ||= User.create!(team: client.owner, user_id: slack_id, user_name: instance_info.name)
    instance.promote! unless instance.captain? || client.owner.captains.count > 0
    instance
  end

  def self.reset_all!(team)
    User.where(team: team).set(wins: 0, losses: 0, ties: 0, elo: 0, tau: 0, rank: nil)
  end

  def to_s
    wins_s = "#{wins} win#{wins != 1 ? 's' : ''}"
    losses_s = "#{losses} loss#{losses != 1 ? 'es' : ''}"
    ties_s = "#{ties} tie#{ties != 1 ? 's' : ''}" if ties && ties > 0
    "#{user_name}: #{[wins_s, losses_s, ties_s].compact.join(', ')} (elo: #{team_elo})"
  end

  def team_elo
    elo + team.elo
  end

  def promote!
    update_attributes!(captain: true)
  end

  def demote!
    update_attributes!(captain: false)
  end

  def register!
    return if registered?
    update_attributes!(registered: true)
    User.rank!(team)
  end

  def unregister!
    return unless registered?
    update_attributes!(registered: false, rank: nil)
    User.rank!(team)
  end

  def rank!
    return unless elo_changed?
    User.rank!(team)
    reload.rank
  end

  def self.rank!(team)
    rank = 1
    players = any_of({ :wins.gt => 0 }, { :losses.gt => 0 }, :ties.gt => 0).where(team: team, registered: true).desc(:elo).desc(:wins).asc(:losses).desc(:ties)
    players.each_with_index do |player, index|
      if player.registered?
        rank += 1 if index > 0 && [:elo, :wins, :losses, :ties].any? { |property| players[index - 1].send(property) != player.send(property) }
        player.set(rank: rank) unless rank == player.rank
      end
    end
  end

  def self.rank_section(team, users)
    ranks = users.map(&:rank)
    return users unless ranks.min && ranks.max
    where(team: team, :rank.gte => ranks.min, :rank.lte => ranks.max).asc(:rank).asc(:wins).asc(:ties)
  end
end
