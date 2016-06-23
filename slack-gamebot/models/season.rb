class Season
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  belongs_to :team, index: true
  belongs_to :created_by, class_name: 'User', inverse_of: nil, index: true
  has_many :challenges
  has_many :matches
  embeds_many :user_ranks

  after_create :archive_challenges!
  after_create :reset_users!

  validate :validate_challenges
  validate :validate_teams
  validates_presence_of :team

  SORT_ORDERS = ['created_at', '-created_at']

  def initialize(attrs = {})
    super
    create_user_ranks
  end

  def to_s
    [
      "#{label}: #{winners ? winners.map(&:to_s).and : 'n/a'}",
      "#{played_challenges.count} match#{played_challenges.count == 1 ? '' : 'es'}",
      "#{players.count} player#{players.count == 1 ? '' : 's'}"
    ].join(', ')
  end

  def winners
    min = user_ranks.min(:rank)
    user_ranks.asc(:id).where(rank: min) if min
  end

  def players
    user_ranks.where(:rank.ne => nil)
  end

  private

  def validate_teams
    teams = [team]
    teams.concat(challenges.map(&:team))
    teams.uniq!
    errors.add(:team, 'Season can only be recorded for one team.') if teams.count != 1
  end

  def played_challenges
    persisted? ? challenges.played : team.challenges.current.played
  end

  def label
    persisted? ? created_at.strftime('%F') : 'Current'
  end

  def validate_challenges
    errors.add(:challenges, 'No matches have been recorded.') unless team.challenges.current.any?
  end

  def create_user_ranks
    return if user_ranks.any?
    team.users.ranked.asc(:rank).asc(:_id).each do |user|
      user_ranks << UserRank.from_user(user)
    end
  end

  def archive_challenges!
    team.challenges.where(
      :state.in => [ChallengeState::PROPOSED, ChallengeState::ACCEPTED]
    ).set(
      state: ChallengeState::CANCELED,
      updated_by_id: created_by && created_by.id
    )
    team.challenges.current.set(season_id: id)
    team.matches.current.set(season_id: id)
  end

  def reset_users!
    User.reset_all!(team)
  end
end
