class Challenge
  include Mongoid::Document
  include Mongoid::Timestamps

  index(state: 1, channel: 1)

  SORT_ORDERS = ['created_at', '-created_at', 'updated_at', '-updated_at', 'state', '-state', 'channel', '-channel'].freeze

  field :state, type: String, default: ChallengeState::PROPOSED
  field :channel, type: String

  belongs_to :team, index: true
  belongs_to :season, inverse_of: :challenges, index: true, optional: true
  belongs_to :created_by, class_name: 'User', inverse_of: nil, index: true, optional: true
  belongs_to :updated_by, class_name: 'User', inverse_of: nil, index: true, optional: true

  has_and_belongs_to_many :challengers, class_name: 'User', inverse_of: nil
  has_and_belongs_to_many :challenged, class_name: 'User', inverse_of: nil

  field :draw_scores, type: Array
  has_and_belongs_to_many :draw, class_name: 'User', inverse_of: nil

  has_one :match

  index({ challenger_ids: 1, state: 1 }, name: 'active_challenger_index')
  index({ challenged_ids: 1, state: 1 }, name: 'active_challenged_index')

  validate :validate_playing_against_themselves
  validate :validate_opponents_counts
  validate :validate_unique_challenge
  validate :validate_teams

  validate :validate_updated_by
  validate :validate_draw_scores
  validates_presence_of :updated_by, if: ->(challenge) { challenge.state != ChallengeState::PROPOSED }
  validates_presence_of :team

  # current challenges are not in an archived season
  scope :current, -> { where(season_id: nil) }

  # challenges scoped by state
  ChallengeState.values.each do |state|
    scope state.to_sym, -> { where(state: state) }
  end

  # Given a challenger and a list of names splits into two groups, returns users.
  def self.split_teammates_and_opponents(client, challenger, names, separator = 'with')
    teammates = [challenger]
    opponents = []
    current_side = opponents

    names.each do |name|
      if name == separator
        current_side = teammates
      else
        current_side << ::User.find_by_slack_mention!(client, name)
      end
    end

    [teammates, opponents]
  end

  def self.new_from_teammates_and_opponents(client, channel, challenger, names, separator = 'with')
    teammates, opponents = split_teammates_and_opponents(client, challenger, names, separator)
    Challenge.new(
      team: client.owner,
      channel: channel,
      created_by: challenger,
      challengers: teammates,
      challenged: opponents,
      state: ChallengeState::PROPOSED
    )
  end

  def self.create_from_teammates_and_opponents!(client, channel, challenger, names, separator = 'with')
    new_from_teammates_and_opponents(client, channel, challenger, names, separator).tap(&:save!)
  end

  def accept!(challenger)
    raise SlackGamebot::Error, "Challenge has already been #{state}." unless state == ChallengeState::PROPOSED

    updates = { updated_by: challenger, state: ChallengeState::ACCEPTED }
    updates[:challenged_ids] = [challenger._id] if open_challenge?
    update_attributes!(updates)
  end

  def decline!(challenger)
    raise SlackGamebot::Error, "Challenge has already been #{state}." unless state == ChallengeState::PROPOSED

    update_attributes!(updated_by: challenger, state: ChallengeState::DECLINED)
  end

  def cancel!(challenger)
    raise SlackGamebot::Error, "Challenge has already been #{state}." unless [ChallengeState::PROPOSED, ChallengeState::ACCEPTED].include?(state)

    update_attributes!(updated_by: challenger, state: ChallengeState::CANCELED)
  end

  def lose!(loser, scores = nil)
    raise SlackGamebot::Error, 'Challenge must first be accepted.' if state == ChallengeState::PROPOSED
    raise SlackGamebot::Error, "Challenge has already been #{state}." unless state == ChallengeState::ACCEPTED

    winners, losers = winners_and_losers_for(loser)
    Match.lose!(team: team, challenge: self, winners: winners, losers: losers, scores: scores)
    update_attributes!(state: ChallengeState::PLAYED)
  end

  def winners_and_losers_for(loser)
    if challenged.include?(loser)
      [challengers, challenged]
    elsif challengers.include?(loser)
      [challenged, challengers]
    else
      raise SlackGamebot::Error, "Only #{(challenged + challengers).map(&:user_name).or} can lose this challenge."
    end
  end

  def resign!(loser, scores = nil)
    raise SlackGamebot::Error, 'Challenge must first be accepted.' if state == ChallengeState::PROPOSED
    raise SlackGamebot::Error, "Challenge has already been #{state}." unless state == ChallengeState::ACCEPTED

    winners, losers = winners_and_losers_for_resigned(loser)
    Match.resign!(team: team, challenge: self, winners: winners, losers: losers, scores: scores)
    update_attributes!(state: ChallengeState::PLAYED)
  end

  def winners_and_losers_for_resigned(loser)
    if challenged.include?(loser)
      [challengers, challenged]
    elsif challengers.include?(loser)
      [challenged, challengers]
    else
      raise SlackGamebot::Error, "Only #{(challenged + challengers).map(&:user_name).or} can resign this challenge."
    end
  end

  def draw!(player, scores = nil)
    raise SlackGamebot::Error, 'Challenge must first be accepted.' if state == ChallengeState::PROPOSED
    raise SlackGamebot::Error, "Challenge has already been #{state}." unless state == ChallengeState::ACCEPTED || state == ChallengeState::DRAWN
    raise SlackGamebot::Error, "Already recorded a draw from #{player.user_name}." if draw.include?(player)

    draw << player
    update_attributes!(state: ChallengeState::DRAWN)
    update_attributes!(draw_scores: scores) if scores
    return if draw.count != (challenged.count + challengers.count)

    # in a draw, winners have a lower original elo
    winners, losers = winners_and_losers_for_draw(player)
    Match.draw!(team: team, challenge: self, winners: winners, losers: losers, scores: scores)
    update_attributes!(state: ChallengeState::PLAYED)
  end

  def winners_and_losers_for_draw(player)
    raise SlackGamebot::Error, "Only #{(challenged + challengers).map(&:user_name).or} can draw this challenge." unless challenged.include?(player) || challengers.include?(player)

    if Elo.team_elo(challenged) < Elo.team_elo(challengers)
      [challenged, challengers]
    else
      [challengers, challenged]
    end
  end

  def to_s
    "a challenge between #{challengers.map(&:display_name).and} and #{challenged.map(&:display_name).and}"
  end

  def self.find_by_user(team, channel, player, states = [ChallengeState::PROPOSED, ChallengeState::ACCEPTED])
    Challenge.any_of(
      { challenger_ids: player._id },
      challenged_ids: player._id
    ).where(
      team: team,
      channel: channel,
      :state.in => states
    ).first
  end

  def self.find_open_challenge(team, channel, states = [ChallengeState::PROPOSED])
    Challenge.where(
      team: team,
      challenged_ids: team.users.everyone.map(&:_id),
      channel: channel,
      :state.in => states
    ).first
  end

  def open_challenge?
    challenged.any?(&:anyone?)
  end

  def draw_scores?
    draw_scores&.any?
  end

  private

  def validate_playing_against_themselves
    intersection = challengers & challenged
    errors.add(:challengers, "Player #{intersection.first.user_name} cannot play against themselves.") if intersection.any?
  end

  def validate_opponents_counts
    return if challengers.any? && challenged.any? && (challengers.count == challenged.count || team.unbalanced)

    errors.add(:challenged, "Number of teammates (#{challengers.count}) and opponents (#{challenged.count}) must match.")
  end

  def validate_teams
    teams = [team]
    teams.concat(challengers.map(&:team))
    teams.concat(challenged.map(&:team))
    teams << match.team if match
    teams << season.team if season
    teams.uniq!
    errors.add(:team, 'Can only play others on the same team.') if teams.count != 1
  end

  def validate_unique_challenge
    return unless state == ChallengeState::PROPOSED || state == ChallengeState::ACCEPTED

    (challengers + challenged).each do |player|
      existing_challenge = ::Challenge.find_by_user(team, channel, player)
      next unless existing_challenge.present?
      next if existing_challenge == self

      errors.add(:challenge, "#{player.user_name} can't play. There's already #{existing_challenge}.")
    end
  end

  def validate_updated_by
    case state
    when ChallengeState::ACCEPTED
      return if updated_by && challenged.include?(updated_by)

      errors.add(:accepted_by, "Only #{challenged.map(&:display_name).and} can accept this challenge.")
    when ChallengeState::DECLINED
      return if updated_by && challenged.include?(updated_by)

      errors.add(:declined_by, "Only #{challenged.map(&:display_name).and} can decline this challenge.")
    when ChallengeState::CANCELED
      return if updated_by && (challengers.include?(updated_by) || challenged.include?(updated_by))

      errors.add(:declined_by, "Only #{challengers.map(&:display_name).and} or #{challenged.map(&:display_name).and} can cancel this challenge.")
    end
  end

  def validate_draw_scores
    return unless draw_scores
    return if Score.tie?(draw_scores)

    errors.add(:scores, 'In a tie both sides must score the same number of points.')
  end
end
