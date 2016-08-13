class Challenge
  include Mongoid::Document
  include Mongoid::Timestamps

  index(state: 1, channel: 1)

  SORT_ORDERS = ['created_at', '-created_at', 'updated_at', '-updated_at', 'state', '-state', 'channel', '-channel']

  field :state, type: String, default: ChallengeState::PROPOSED
  field :channel, type: String

  belongs_to :team, index: true
  belongs_to :season, inverse_of: :challenges, index: true
  belongs_to :created_by, class_name: 'User', inverse_of: nil, index: true
  belongs_to :updated_by, class_name: 'User', inverse_of: nil, index: true

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
  def self.split_teammates_and_opponents(team, challenger, names, separator = 'with')
    teammates = [challenger]
    opponents = []
    current_side = opponents

    names.each do |name|
      if name == separator
        current_side = teammates
      else
        current_side << ::User.find_by_slack_mention!(team, name)
      end
    end

    [teammates, opponents]
  end

  def self.create_from_teammates_and_opponents!(team, channel, challenger, names, separator = 'with')
    teammates, opponents = split_teammates_and_opponents(team, challenger, names, separator)
    Challenge.create!(
      team: team,
      channel: channel,
      created_by: challenger,
      challengers: teammates,
      challenged: opponents,
      state: ChallengeState::PROPOSED
    )
  end

  def accept!(challenger)
    fail SlackGamebot::Error, "Challenge has already been #{state}." unless state == ChallengeState::PROPOSED
    update_attributes!(updated_by: challenger, state: ChallengeState::ACCEPTED)
  end

  def decline!(challenger)
    fail SlackGamebot::Error, "Challenge has already been #{state}." unless state == ChallengeState::PROPOSED
    update_attributes!(updated_by: challenger, state: ChallengeState::DECLINED)
  end

  def cancel!(challenger)
    fail SlackGamebot::Error, "Challenge has already been #{state}." unless [ChallengeState::PROPOSED, ChallengeState::ACCEPTED].include?(state)
    update_attributes!(updated_by: challenger, state: ChallengeState::CANCELED)
  end

  def lose!(loser, scores = nil)
    fail SlackGamebot::Error, 'Challenge must first be accepted.' if state == ChallengeState::PROPOSED
    fail SlackGamebot::Error, "Challenge has already been #{state}." unless state == ChallengeState::ACCEPTED
    winners = nil
    losers = nil
    if challenged.include?(loser)
      winners = challengers
      losers = challenged
    elsif
      winners = challenged
      losers = challengers
    else
      fail SlackGamebot::Error, "Only #{(challenged + challengers).map(&:user_name).or} can lose this challenge."
    end
    Match.lose!(team: team, challenge: self, winners: winners, losers: losers, scores: scores)
    update_attributes!(state: ChallengeState::PLAYED)
  end

  def resign!(loser, scores = nil)
    fail SlackGamebot::Error, 'Challenge must first be accepted.' if state == ChallengeState::PROPOSED
    fail SlackGamebot::Error, "Challenge has already been #{state}." unless state == ChallengeState::ACCEPTED
    winners = nil
    losers = nil
    if challenged.include?(loser)
      winners = challengers
      losers = challenged
    elsif
      winners = challenged
      losers = challengers
    else
      fail SlackGamebot::Error, "Only #{(challenged + challengers).map(&:user_name).or} can lose this challenge."
    end
    Match.resign!(team: team, challenge: self, winners: winners, losers: losers, scores: scores)
    update_attributes!(state: ChallengeState::PLAYED)
  end

  def draw!(player, scores = nil)
    fail SlackGamebot::Error, 'Challenge must first be accepted.' if state == ChallengeState::PROPOSED
    fail SlackGamebot::Error, "Challenge has already been #{state}." unless state == ChallengeState::ACCEPTED
    fail SlackGamebot::Error, "Already recorded a draw from #{player.user_name}." if draw.include?(player)
    draw << player
    update_attributes!(draw_scores: scores) if scores
    return if draw.count != (challenged.count + challengers.count)
    # in a draw, winners have a lower original elo
    winners = nil
    losers = nil
    if Elo.team_elo(challenged) < Elo.team_elo(challengers)
      winners = challenged
      losers = challengers
    else
      losers = challenged
      winners = challengers
    end
    Match.draw!(team: team, challenge: self, winners: winners, losers: losers, scores: scores)
    update_attributes!(state: ChallengeState::PLAYED)
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

  def draw_scores?
    draw_scores && draw_scores.any?
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
      errors.add(:accepted_by, "Only #{challenged.map(&:user_name).and} can accept this challenge.")
    when ChallengeState::DECLINED
      return if updated_by && challenged.include?(updated_by)
      errors.add(:declined_by, "Only #{challenged.map(&:user_name).and} can decline this challenge.")
    when ChallengeState::CANCELED
      return if updated_by && (challengers.include?(updated_by) || challenged.include?(updated_by))
      errors.add(:declined_by, "Only #{challengers.map(&:user_name).and} or #{challenged.map(&:user_name).and} can cancel this challenge.")
    end
  end

  def validate_draw_scores
    return unless draw_scores
    return if Score.tie?(draw_scores)
    errors.add(:scores, 'In a tie both sides must score the same number of points.')
  end
end
