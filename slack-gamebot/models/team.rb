class Team
  include Mongoid::Document
  include Mongoid::Timestamps

  SORT_ORDERS = ['created_at', '-created_at', 'updated_at', '-updated_at']

  field :team_id, type: String
  field :name, type: String
  field :domain, type: String
  field :token, type: String
  field :active, type: Boolean, default: true
  field :gifs, type: Boolean, default: true
  field :api, type: Boolean, default: false
  field :aliases, type: Array, default: []
  field :nudge_at, type: DateTime

  scope :active, -> { where(active: true) }
  scope :api, -> { where(api: true) }

  validates_uniqueness_of :token, message: 'has already been used'
  validates_presence_of :token
  validates_presence_of :team_id
  validates_presence_of :game_id

  has_many :users, dependent: :destroy
  has_many :seasons, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_many :challenges, dependent: :destroy

  belongs_to :game

  def captains
    users.captains
  end

  def deactivate!
    update_attributes!(active: false)
  end

  def activate!(token)
    update_attributes!(active: true, token: token)
  end

  def to_s
    {
      game: game.name,
      name: name,
      domain: domain,
      id: team_id
    }.map do |k, v|
      "#{k}=#{v}" if v
    end.compact.join(', ')
  end

  def ping!
    client = Slack::Web::Client.new(token: token)
    auth = client.auth_test
    {
      auth: auth,
      presence: client.users_getPresence(user: auth['user_id'])
    }
  end

  def asleep?(dt = 2.weeks)
    time_limit = Time.now - dt
    return false if created_at > time_limit
    recent_challenge = challenges.desc(:updated_at).limit(1).first
    recent_challenge.nil? || recent_challenge.updated_at < time_limit
  end

  def nudge?(dt = 2.weeks)
    time_limit = Time.now - dt
    return false if nudge_at && nudge_at > time_limit
    asleep?(dt)
  end

  def dead?(dt = 8.weeks)
    asleep?(dt)
  end

  def nudge!
    inform! "Challenge someone to a game of #{game.name} today!", 'nudge'
  end

  def inform!(message, gif = nil)
    client = Slack::Web::Client.new(token: token)
    channels = client.channels_list['channels'].select { |channel| channel['is_member'] }
    return unless channels.any?
    channel = channels.first
    logger.info "Sending '#{message}' to #{self} on ##{channel['name']}."
    gif = begin
      Giphy.random(gif)
    rescue StandardError => e
      logger.warn "Giphy.random: #{e.message}"
      nil
    end if gif && gifs?
    text = [message, gif && gif.image_url.to_s].compact.join("\n")
    client.chat_postMessage(text: text, channel: channel['id'], as_user: true)
    update_attributes!(nudge_at: Time.now)
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
    team.game = Game.first || Game.create!(name: 'default')
    team.save!
    team
  end

  def self.purge!
    # destroy teams inactive for two weeks
    Team.where(active: false, :updated_at.lte => 2.weeks.ago).each do |team|
      Mongoid.logger.info "Destroying #{team}, inactive since #{team.updated_at}, over two weeks ago."
      team.destroy
    end
  end
end
