class Challenge
  include Mongoid::Document
  include Mongoid::Timestamps

  field :state, type: String, default: ChallengeState::PROPOSED
  belongs_to :created_by, class_name: 'User', inverse_of: nil
  belongs_to :accepted_by, class_name: 'User', inverse_of: nil
  belongs_to :declined_by, class_name: 'User', inverse_of: nil

  has_and_belongs_to_many :challengers, class_name: 'User', inverse_of: nil
  has_and_belongs_to_many :challenged, class_name: 'User', inverse_of: nil

  index({ challenger_ids: 1, challenged_ids: 1, state: 1 }, name: 'active_challenge_index')

  validate :validate_playing_against_themselves
  validate :validate_opponents_counts
  validate :validate_unique_challenge

  validate :validate_accepted_by
  validates_presence_of :accepted_by, if: ->(challenge) { challenge.state == ChallengeState::ACCEPTED }

  validate :validate_declined_by
  validates_presence_of :declined_by, if: ->(challenge) { challenge.state == ChallengeState::DECLINED }

  # Given a challenger and a list of names splits into two groups, returns users.
  def self.split_teammates_and_opponents(challenger, names, separator = 'with')
    teammates = [challenger]
    opponents = []
    current_side = opponents

    names.each do |name|
      if name == separator
        current_side = teammates
      else
        user = User.find_by_slack_mention(name)
        fail ArgumentError, "I don't know who #{name} is! Ask them to _#{SlackGamebot.config.user} register_." unless user
        current_side << user
      end
    end

    [teammates, opponents]
  end

  def self.create_from_teammates_and_opponents!(challenger, names, separator = 'with')
    teammates, opponents = split_teammates_and_opponents(challenger, names, separator)
    Challenge.create!(
      created_by: challenger,
      challengers: teammates,
      challenged: opponents,
      state: ChallengeState::PROPOSED
    )
  end

  def accept!(challenger)
    fail "Challenge has already been #{state}." unless state == ChallengeState::PROPOSED
    update_attributes!(accepted_by: challenger, state: ChallengeState::ACCEPTED)
  end

  def decline!(challenger)
    fail "Challenge has already been #{state}." unless state == ChallengeState::PROPOSED
    update_attributes!(declined_by: challenger, state: ChallengeState::DECLINED)
  end

  def to_s
    "a challenge between between #{challengers.map(&:user_name).join(' and ')} and #{challenged.map(&:user_name).join(' and ')}"
  end

  def self.find_by_user(player)
    Challenge.any_of(
      { challenger_ids: player._id },
      challenged_ids: player._id
    ).where(
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
      existing_challenge = Challenge.find_by_user(player)
      next unless existing_challenge.present?
      next if existing_challenge == self
      errors.add(:challenge, "#{player.user_name} can't play. There's already #{existing_challenge}.")
    end
  end

  def validate_accepted_by
    return unless accepted_by && state == ChallengeState::ACCEPTED
    return if challenged.include?(accepted_by)
    errors.add(:accepted_by, "Only #{challenged.map(&:user_name).join(' and ')} can accept this challenge.")
  end

  def validate_declined_by
    return unless declined_by && state == ChallengeState::DECLINED
    return if challenged.include?(declined_by)
    errors.add(:accepted_by, "Only #{challenged.map(&:user_name).join(' and ')} can decline this challenge.")
  end
end
