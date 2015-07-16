class Season
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :created_by, class_name: 'User', inverse_of: nil, index: true
  has_many :challenges
  embeds_many :user_ranks

  before_create :create_user_ranks

  after_create :archive_challenges!
  after_create :reset_users!

  private

  def create_user_ranks
    User.desc(:rank).each do |user|
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
