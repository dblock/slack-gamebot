class Team
  field :gifs, type: Boolean, default: true
  field :api, type: Boolean, default: false
  field :aliases, type: Array, default: []
  field :dead_at, type: DateTime
  field :elo, type: Integer, default: 0
  field :unbalanced, type: Boolean, default: false

  field :stripe_customer_id, type: String
  field :subscribed, type: Boolean, default: false

  scope :api, -> { where(api: true) }
  scope :subscribed, -> { where(subscribed: true) }

  validates_presence_of :game_id

  has_many :users, dependent: :destroy
  has_many :seasons, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_many :challenges, dependent: :destroy

  belongs_to :game

  after_update :inform_subscribed_changed!

  def subscripion_expired?
    return false if subscribed?
    return false if Time.now.utc < DateTime.parse('2018/5/15') # temporary
    time_limit = Time.now.utc - 2.weeks
    return false if created_at > time_limit
    true
  end

  def subscribe_text
    "Subscribe your team for $29.99 a year at #{SlackGamebot::Service.url}/subscribe?team_id=#{team_id}&game=#{game.name}."
  end

  def update_cc_text
    "Update your credit card info at #{SlackGamebot::Service.url}/update_cc?team_id=#{team_id}&game=#{game.name}."
  end

  def captains
    users.captains
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

  def asleep?(dt = 2.weeks)
    time_limit = Time.now.utc - dt
    return false if created_at > time_limit
    recent_match = matches.desc(:updated_at).limit(1).first
    return false if recent_match && recent_match.updated_at >= time_limit
    recent_challenge = challenges.desc(:updated_at).limit(1).first
    return false if recent_challenge && recent_challenge.updated_at >= time_limit
    true
  end

  def dead?(dt = 1.month)
    asleep?(dt)
  end

  def dead!(message, gif = nil)
    inform! message, gif
    inform_admins! message, gif
    update_attributes!(dead_at: Time.now.utc)
  end

  def api_url
    return unless api?
    "#{SlackGamebot::Service.api_url}/teams/#{id}"
  end

  def inform!(message, gif_name = nil)
    client = Slack::Web::Client.new(token: token)
    channels = client.channels_list['channels'].select { |channel| channel['is_member'] } # TODO: paginate
    channels.each do |channel|
      logger.info "Sending '#{message}' to #{self} on ##{channel['name']}."
      client.chat_postMessage(text: make_message(message, gif_name), channel: channel['id'], as_user: true)
    end
  end

  def inform_admins!(message, gif_name = nil)
    client = Slack::Web::Client.new(token: token)
    members = client.users_list(presence: false).members.flatten # TODO: paginate
    members.select(&:is_admin).each do |admin|
      channel = client.im_open(user: admin.id)
      logger.info "Sending DM '#{message}' to #{admin.name}."
      client.chat_postMessage(text: make_message(message, gif_name), channel: channel.channel.id, as_user: true)
    end
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

  private

  SUBSCRIBED_TEXT = <<-EOS.freeze
Your team has been subscribed. Thank you!
Follow https://twitter.com/playplayio for news and updates.
EOS

  def make_message(message, gif_name = nil)
    if gif_name && gifs?
      gif = begin
        Giphy.random(gif_name)
      rescue StandardError => e
        logger.warn "Giphy.random: #{e.message}"
        nil
      end
    end
    [message, gif && gif.image_url.to_s].compact.join("\n")
  end

  def inform_subscribed_changed!
    return unless subscribed? && subscribed_changed?
    inform! SUBSCRIBED_TEXT, 'thanks'
  end
end
