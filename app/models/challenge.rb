class Challenge
  include Mongoid::Document
  include Mongoid::Timestamps

  index(state: 1, channel: 1)

  SORT_ORDERS = ['created_at', '-created_at', 'updated_at', '-updated_at', 'state', '-state', 'channel', '-channel']

  field :state, type: String, default: ChallengeState::PROPOSED
  field :channel, type: String

  belongs_to :created_by, class_name: 'User', inverse_of: nil, index: true
  belongs_to :updated_by, class_name: 'User', inverse_of: nil, index: true

  has_and_belongs_to_many :challengers, class_name: 'User', inverse_of: nil
  has_and_belongs_to_many :challenged, class_name: 'User', inverse_of: nil

  has_one :match

  index({ challenger_ids: 1, challenged_ids: 1, state: 1 }, name: 'active_challenge_index')

  validate :validate_playing_against_themselves
  validate :validate_opponents_counts
  validate :validate_unique_challenge

  validate :validate_updated_by
  validates_presence_of :updated_by, if: ->(challenge) { challenge.state != ChallengeState::PROPOSED }

  # Given a challenger and a list of names splits into two groups, returns users.
  def self.split_teammates_and_opponents(challenger, names, separator = 'with')
    teammates = [challenger]
    opponents = []
    current_side = opponents

    names.each do |name|
      if name == separator
        current_side = teammates
      else
        current_side << ::User.find_by_slack_mention!(name)
      end
    end

    [teammates, opponents]
  end

  def self.create_from_teammates_and_opponents!(channel, challenger, names, separator = 'with')
    teammates, opponents = split_teammates_and_opponents(challenger, names, separator)
    Challenge.create!(
      channel: channel,
      created_by: challenger,
      challengers: teammates,
      challenged: opponents,
      state: ChallengeState::PROPOSED
    )
  end

  def accept!(challenger)
    fail "Challenge has already been #{state}." unless state == ChallengeState::PROPOSED
    update_attributes!(updated_by: challenger, state: ChallengeState::ACCEPTED)
  end

  def decline!(challenger)
    fail "Challenge has already been #{state}." unless state == ChallengeState::PROPOSED
    update_attributes!(updated_by: challenger, state: ChallengeState::DECLINED)
  end

  def cancel!(challenger)
    fail "Challenge has already been #{state}." unless [ChallengeState::PROPOSED, ChallengeState::ACCEPTED].include?(state)
    update_attributes!(updated_by: challenger, state: ChallengeState::CANCELED)
  end

  def lose!(loser)
    fail 'Challenge must first be accepted.' if state == ChallengeState::PROPOSED
    fail "Challenge has already been #{state}." unless state == ChallengeState::ACCEPTED
    winners = nil
    losers = nil
    if challenged.include?(loser)
      winners = challengers
      losers = challenged
    elsif
      winners = challenged
      losers = challengers
    else
      fail "Only #{(challenged + challengers).map(&:user_name).join(' or ')} can lose this challenge."
    end
    winners.inc(wins: 1)
    losers.inc(losses: 1)
    Match.create!(challenge: self, winners: winners, losers: losers)
    update_attributes!(state: ChallengeState::PLAYED)
  end

  def to_s
    "a challenge between #{challengers.map(&:user_name).join(' and ')} and #{challenged.map(&:user_name).join(' and ')}"
  end

  def self.find_by_user(channel, player)
    Challenge.any_of(
      { challenger_ids: player._id },
      challenged_ids: player._id
    ).where(
      channel: channel,
      :state.in => [
        ChallengeState::PROPOSED,
        ChallengeState::ACCEPTED
      ]
    ).first
  end

  private

  def validate_playing_against_themselves
    intersection = challengers & challenged
    errors.add(:challengers, "Player #{intersection.first.user_name} cannot play against themselves.") if intersection.any?
  end

  def validate_opponents_counts
    errors.add(:challenged, "Number of teammates (#{challengers.count}) and opponents (#{challenged.count}) must match.") if challengers.count != challenged.count
  end

  def validate_unique_challenge
    (challengers + challenged).each do |player|
      existing_challenge = ::Challenge.find_by_user(channel, player)
      next unless existing_challenge.present?
      next if existing_challenge == self
      errors.add(:challenge, "#{player.user_name} can't play. There's already #{existing_challenge}.")
    end
  end

  def validate_updated_by
    case state
    when ChallengeState::ACCEPTED
      return if updated_by && challenged.include?(updated_by)
      errors.add(:accepted_by, "Only #{challenged.map(&:user_name).join(' and ')} can accept this challenge.")
    when ChallengeState::DECLINED
      return if updated_by && challenged.include?(updated_by)
      errors.add(:declined_by, "Only #{challenged.map(&:user_name).join(' and ')} can decline this challenge.")
    when ChallengeState::CANCELED
      return if updated_by && (challengers.include?(updated_by) || challenged.include?(updated_by))
      errors.add(:declined_by, "Only #{challengers.map(&:user_name).join(' and ')} or #{challenged.map(&:user_name).join(' and ')} can cancel this challenge.")
    end
  end
end
