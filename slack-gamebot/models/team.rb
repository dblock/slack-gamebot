class Team
  include Mongoid::Document
  include Mongoid::Timestamps

  SORT_ORDERS = ['created_at', '-created_at', 'updated_at', '-updated_at']

  field :team_id, type: String
  field :name, type: String
  field :domain, type: String
  field :token, type: String
  field :active, type: Boolean, default: true

  scope :active, -> { where(active: true) }

  validates_uniqueness_of :token, message: 'has already been used'
  validates_presence_of :token
  validates_presence_of :team_id
  validates_presence_of :game_id

  has_many :users
  has_many :seasons
  has_many :matches
  has_many :challenges

  belongs_to :game

  def captains
    users.captains
  end

  def deactivate!
    update_attributes!(active: false)
  end

  def activate!
    update_attributes!(active: true)
  end

  def to_s
    "game=#{game.try(:name)}, name=#{name}, domain=#{domain}, id=#{team_id}"
  end

  def ping!
    client = Slack::Web::Client.new(token: token)
    auth = client.auth_test
    {
      auth: auth,
      presence: client.users_getPresence(user: auth['user_id'])
    }
  end

  def self.find_or_create_from_env!
    token = ENV['SLACK_API_TOKEN']
    return unless token
    team = Team.where(token: token).first
    team ||= Team.new(token: token)
    info = Slack::Web::Client.new(token: token).team_info
    team.team_id = info['team']['id']
    team.name = info['team']['name']
    team.domain = info['team']['domain']
    team.game = Game.first
    team.save!
    team
  end
end
