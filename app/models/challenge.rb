class Challenge
  include Mongoid::Document
  include Mongoid::Timestamps

  field :state, type: String, default: ChallengeState::PROPOSED
  belongs_to :created_by, class_name: 'User', inverse_of: nil

  has_and_belongs_to_many :challengers, class_name: 'User', inverse_of: nil
  has_and_belongs_to_many :challenged, class_name: 'User', inverse_of: nil

  index({ challenger_ids: 1, challenged_ids: 1, state: 1 }, name: 'active_challenge_index')

  validate :validate_playing_against_themselves
  validate :validate_opponents_counts
  validate :validate_unique_challenge

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
    Challenge.create!(created_by: challenger, challengers: teammates, challenged: opponents, state: ChallengeState::PROPOSED)
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
      existing_challenge = Challenge.any_of({ challenger_ids: player._id }, challenged_ids: player._id).where(:state.in => [ChallengeState::PROPOSED, ChallengeState::ACCEPTED]).first
      next unless existing_challenge
      errors.add(:challenge, "#{player.user_name} can't play. There's already a #{existing_challenge.state} challenge between #{existing_challenge.challengers.map(&:user_name).join(' and ')} and #{existing_challenge.challenged.map(&:user_name).join(' and ')}.")
    end
  end
end
