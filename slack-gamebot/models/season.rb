class Season
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :created_by, class_name: 'User', inverse_of: nil, index: true
  has_many :challenges
  embeds_many :user_ranks

  after_create :archive_challenges!
  after_create :reset_users!

  validate :validate_challenges

  def initialize(attrs = {})
    super
    create_user_ranks
  end

  def to_s
    [
      "#{label}: #{winner}",
      "#{played_challenges.count} match#{played_challenges.count == 1 ? '' : 'es'}",
      "#{players.count} player#{players.count == 1 ? '' : 's'}"
    ].join(', ')
  end

  private

  def winner
    user_ranks.asc(:rank).first
  end

  def played_challenges
    persisted? ? challenges.played : Challenge.current
  end

  def label
    persisted? ? created_at.strftime('%F') : 'Current'
  end

  def players
    user_ranks.where(:rank.ne => nil)
  end

  def validate_challenges
    errors.add(:challenges, 'No matches have been recorded.') unless Challenge.current.any?
  end

  def create_user_ranks
    return if user_ranks.any?
    User.asc(:rank).each do |user|
      user_ranks << UserRank.from_user(user)
    end
  end

  def archive_challenges!
    Challenge.where(
      :state.in => [ChallengeState::PROPOSED, ChallengeState::ACCEPTED]
    ).set(
      state: ChallengeState::CANCELED,
      updated_by_id: created_by && created_by.id
    )
    Challenge.current.set(season_id: id)
  end

  def reset_users!
    User.reset_all!
  end
end
