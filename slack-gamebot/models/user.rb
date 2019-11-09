class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :user_name, type: String
  field :wins, type: Integer, default: 0
  field :losses, type: Integer, default: 0
  field :losing_streak, type: Integer, default: 0
  field :winning_streak, type: Integer, default: 0
  field :ties, type: Integer, default: 0
  field :elo, type: Integer, default: 0
  field :elo_history, type: Array, default: []
  field :tau, type: Float, default: 0
  field :rank, type: Integer
  field :captain, type: Boolean, default: false
  field :registered, type: Boolean, default: true
  field :nickname, type: String

  belongs_to :team, index: true
  validates_presence_of :team

  index({ user_id: 1, team_id: 1 }, unique: true)
  index(user_name: 1, team_id: 1)
  index(wins: 1, team_id: 1)
  index(losses: 1, team_id: 1)
  index(ties: 1, team_id: 1)
  index(elo: 1, team_id: 1)

  before_save :update_elo_history!
  after_save :rank!

  SORT_ORDERS = ['elo', '-elo', 'created_at', '-created_at', 'wins', '-wins', 'losses', '-losses', 'ties', '-ties', 'user_name', '-user_name', 'rank', '-rank'].freeze
  ANYONE = '*'.freeze
  EVERYONE = %w[here channel].freeze

  scope :ranked, -> { where(:rank.ne => nil) }
  scope :captains, -> { where(captain: true) }
  scope :everyone, -> { where(user_id: ANYONE) }

  def current_matches
    Match.current.where(team: team).or({ winner_ids: _id }, loser_ids: _id)
  end

  def slack_mention
    anyone? ? 'anyone' : "<@#{user_id}>"
  end

  def display_name
    registered ? nickname || user_name : '<unregistered>'
  end

  def anyone?
    user_id == ANYONE
  end

  def self.slack_mention?(user_name)
    slack_id = ::Regexp.last_match[1] if user_name =~ /^<[@!](.*)>$/
    slack_id = ANYONE if slack_id && EVERYONE.include?(slack_id)
    slack_id
  end

  def self.find_by_slack_mention!(client, user_name)
    team = client.owner
    slack_id = slack_mention?(user_name)
    user = if slack_id
             team.users.where(user_id: slack_id).first
           else
             regexp = ::Regexp.new("^#{user_name}$", 'i')
             User.where(team: team).or({ user_name: regexp }, nickname: regexp).first
    end
    unless user
      case slack_id
      when ANYONE then
        user = User.create!(team: team, user_id: ANYONE, user_name: ANYONE, nickname: 'anyone', registered: true)
      else
        begin
          users_info = client.web_client.users_info(user: slack_id || "@#{user_name}")
          info = Hashie::Mash.new(users_info).user if users_info
          user = User.create!(team: team, user_id: info.id, user_name: info.name, registered: true) if info
        rescue Slack::Web::Api::Errors::SlackError => e
          raise e unless e.message == 'user_not_found'
        end
      end
    end
    raise SlackGamebot::Error, "I don't know who #{user_name} is! Ask them to _register_." unless user&.registered?
    raise SlackGamebot::Error, "I don't know who #{user_name} is!" unless user

    user
  end

  def self.find_many_by_slack_mention!(client, user_names)
    user_names.map { |user| find_by_slack_mention!(client, user) }
  end

  # Find an existing record, update the username if necessary, otherwise create a user record.
  def self.find_create_or_update_by_slack_id!(client, slack_id)
    instance = User.where(team: client.owner, user_id: slack_id).first
    users_info = client.web_client.users_info(user: slack_id)
    instance_info = Hashie::Mash.new(users_info).user if users_info
    if users_info && instance
      instance.update_attributes!(user_name: instance_info.name) if instance.user_name != instance_info.name
    elsif !instance && instance_info
      instance = User.create!(team: client.owner, user_id: slack_id, user_name: instance_info.name, registered: true)
    end
    if instance
      instance.register! unless instance.registered?
      instance.promote! unless instance.captain? || client.owner.captains.count > 0
    end
    raise SlackGamebot::Error, "I don't know who <@#{slack_id}> is!" unless instance

    instance
  end

  def self.reset_all!(team)
    User.where(team: team).set(
      wins: 0,
      losses: 0,
      ties: 0,
      elo: 0,
      elo_history: [],
      tau: 0,
      rank: nil,
      losing_streak: 0,
      winning_streak: 0
    )
  end

  def to_s
    wins_s = "#{wins} win#{wins != 1 ? 's' : ''}"
    losses_s = "#{losses} loss#{losses != 1 ? 'es' : ''}"
    ties_s = "#{ties} tie#{ties != 1 ? 's' : ''}" if ties && ties > 0
    elo_s = "elo: #{team_elo}"
    lws_s = "lws: #{winning_streak}" if winning_streak >= losing_streak && winning_streak >= 3
    lls_s = "lls: #{losing_streak}" if losing_streak > winning_streak && losing_streak >= 3
    "#{display_name}: #{[wins_s, losses_s, ties_s].compact.join(', ')} (#{[elo_s, lws_s, lls_s].compact.join(', ')})"
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

  def update_elo_history!
    return unless elo_changed?

    elo_history << elo
  end

  def self.rank!(team)
    rank = 1
    players = any_of({ :wins.gt => 0 }, { :losses.gt => 0 }, :ties.gt => 0).where(team: team, registered: true).desc(:elo).desc(:wins).asc(:losses).desc(:ties)
    players.each_with_index do |player, index|
      if player.registered?
        rank += 1 if index > 0 && %i[elo wins losses ties].any? { |property| players[index - 1].send(property) != player.send(property) }
        player.set(rank: rank) unless rank == player.rank
      end
    end
  end

  def calculate_streaks!
    longest_winning_streak = 0
    longest_losing_streak = 0
    current_winning_streak = 0
    current_losing_streak = 0
    current_matches.asc(:_id).each do |match|
      if match.tied?
        current_winning_streak = 0
        current_losing_streak = 0
      elsif match.winner_ids.include?(_id)
        current_losing_streak = 0
        current_winning_streak += 1
      else
        current_winning_streak = 0
        current_losing_streak += 1
      end
      longest_losing_streak = current_losing_streak if current_losing_streak > longest_losing_streak
      longest_winning_streak = current_winning_streak if current_winning_streak > longest_winning_streak
    end
    return if losing_streak == longest_losing_streak && winning_streak == longest_winning_streak

    update_attributes!(losing_streak: longest_losing_streak, winning_streak: longest_winning_streak)
  end

  def self.rank_section(team, users)
    ranks = users.map(&:rank)
    return users unless ranks.min && ranks.max

    where(team: team, :rank.gte => ranks.min, :rank.lte => ranks.max).asc(:rank).asc(:wins).asc(:ties)
  end
end
