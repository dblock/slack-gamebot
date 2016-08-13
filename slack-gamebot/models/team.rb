class Team
  field :gifs, type: Boolean, default: true
  field :api, type: Boolean, default: false
  field :aliases, type: Array, default: []
  field :nudge_at, type: DateTime
  field :elo, type: Integer, default: 0
  field :unbalanced, type: Boolean, default: false

  field :stripe_customer_id, type: String
  field :premium, type: Boolean, default: false

  scope :api, -> { where(api: true) }

  validates_presence_of :game_id

  has_many :users, dependent: :destroy
  has_many :seasons, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_many :challenges, dependent: :destroy

  belongs_to :game

  after_update :inform_premium_changed!

  def premium_text
    "This is a premium feature. #{upgrade_text}"
  end

  def upgrade_text
    "Upgrade your team to premium for $29.99 a year at https://www.playplay.io/upgrade?team_id=#{team_id}&game=#{game.name}."
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
    time_limit = Time.now - dt
    return false if created_at > time_limit
    recent_match = matches.desc(:updated_at).limit(1).first
    return false if recent_match && recent_match.updated_at >= time_limit
    recent_challenge = challenges.desc(:updated_at).limit(1).first
    return false if recent_challenge && recent_challenge.updated_at >= time_limit
    true
  end

  def nudge?(dt = 2.weeks)
    time_limit = Time.now - dt
    return false if nudge_at && nudge_at > time_limit
    asleep?(dt)
  end

  def dead?(dt = 4.weeks)
    asleep?(dt)
  end

  def nudge!
    inform! "Challenge someone to a game of #{game.name} today!", 'nudge'
    update_attributes!(nudge_at: Time.now)
  end

  def api_url
    return unless api? && ENV.key?('API_URL')
    "#{ENV['API_URL']}/teams/#{id}"
  end

  def inform!(message, gif_name = nil)
    client = Slack::Web::Client.new(token: token)
    channels = client.channels_list['channels'].select { |channel| channel['is_member'] }
    return unless channels.any?
    channel = channels.first
    logger.info "Sending '#{message}' to #{self} on ##{channel['name']}."
    gif = begin
      Giphy.random(gif_name)
    rescue StandardError => e
      logger.warn "Giphy.random: #{e.message}"
      nil
    end if gif_name && gifs?
    text = [message, gif && gif.image_url.to_s].compact.join("\n")
    client.chat_postMessage(text: text, channel: channel['id'], as_user: true)
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

  UPGRADED_TEXT = <<-EOS
Your team has been upgraded, enjoy all premium features. Thanks for supporting open-source!
Follow https://twitter.com/playplayio for news and updates.
EOS

  def inform_premium_changed!
    return unless premium? && premium_changed?
    inform! UPGRADED_TEXT, 'thanks'
  end
end
