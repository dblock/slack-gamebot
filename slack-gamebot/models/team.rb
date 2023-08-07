class Team
  field :gifs, type: Boolean, default: true
  field :api, type: Boolean, default: false
  field :aliases, type: Array, default: []
  field :dead_at, type: DateTime
  field :trial_informed_at, type: DateTime
  field :elo, type: Integer, default: 0
  field :unbalanced, type: Boolean, default: false
  field :leaderboard_max, type: Integer

  field :stripe_customer_id, type: String
  field :subscribed, type: Boolean, default: false
  field :subscribed_at, type: DateTime

  scope :api, -> { where(api: true) }
  scope :subscribed, -> { where(subscribed: true) }

  validates_presence_of :game_id

  has_many :users, dependent: :destroy
  has_many :seasons, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_many :challenges, dependent: :destroy

  belongs_to :game

  before_validation :update_subscribed_at
  after_update :subscribed!
  after_save :activated!

  def subscription_expired?
    return false if subscribed?

    time_limit = Time.now.utc - 2.weeks
    return false if created_at > time_limit

    true
  end

  def trial_ends_at
    raise 'Team is subscribed.' if subscribed?

    created_at + 2.weeks
  end

  def remaining_trial_days
    raise 'Team is subscribed.' if subscribed?

    [0, (trial_ends_at.to_date - Time.now.utc.to_date).to_i].max
  end

  def trial_message
    [
      if remaining_trial_days.zero?
        'Your trial subscription has expired.'
      else
        "Your trial subscription expires in #{remaining_trial_days} day#{remaining_trial_days == 1 ? '' : 's'}."
      end,
      subscribe_text
    ].join(' ')
  end

  def inform_trial!
    return if subscribed? || subscription_expired?
    return if trial_informed_at && (Time.now.utc < trial_informed_at + 7.days)

    inform! trial_message
    inform_admin! trial_message
    update_attributes!(trial_informed_at: Time.now.utc)
  end

  def subscribe_text
    "Subscribe your team for $29.99 a year at #{SlackRubyBotServer::Service.url}/subscribe?team_id=#{team_id}&game=#{game.name}."
  end

  def update_cc_text
    "Update your credit card info at #{SlackRubyBotServer::Service.url}/update_cc?team_id=#{team_id}&game=#{game.name}."
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
    inform_admin! message, gif
  ensure
    update_attributes!(dead_at: Time.now.utc)
  end

  def api_url
    return unless api?

    "#{SlackRubyBotServer::Service.api_url}/teams/#{id}"
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: token)
  end

  def slack_channels
    raise 'missing bot_user_id' unless bot_user_id

    channels = []
    slack_client.users_conversations(
      user: bot_user_id,
      exclude_archived: true,
      types: 'public_channel,private_channel'
    ) do |response|
      channels.concat(response.channels)
    end
    channels
  end

  def inform!(message, gif_name = nil)
    slack_channels.each do |channel|
      logger.info "Sending '#{message}' to #{self} on ##{channel['name']}."
      slack_client.chat_postMessage(text: make_message(message, gif_name), channel: channel['id'], as_user: true)
    end
  end

  def inform_admin!(message, gif_name = nil)
    return unless activated_user_id

    channel = slack_client.conversations_open(users: activated_user_id.to_s)
    logger.info "Sending DM '#{message}' to #{activated_user_id}."
    slack_client.chat_postMessage(text: make_message(message, gif_name), channel: channel.channel.id, as_user: true)
  end

  def self.find_or_create_from_env!
    token = ENV.fetch('SLACK_API_TOKEN', nil)
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

  def stripe_customer
    return unless stripe_customer_id

    @stripe_customer ||= Stripe::Customer.retrieve(stripe_customer_id)
  end

  def stripe_customer_text
    "Customer since #{Time.at(stripe_customer.created).strftime('%B %d, %Y')}."
  end

  def subscriber_text
    return unless subscribed_at

    "Subscriber since #{subscribed_at.strftime('%B %d, %Y')}."
  end

  def stripe_subcriptions
    return unless stripe_customer

    stripe_customer.subscriptions
  end

  def stripe_customer_subscriptions_info(with_unsubscribe = false)
    stripe_customer.subscriptions.map do |subscription|
      amount = ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)
      current_period_end = Time.at(subscription.current_period_end).strftime('%B %d, %Y')
      if subscription.status == 'active'
        [
          "Subscribed to #{subscription.plan.name} (#{amount}), will#{subscription.cancel_at_period_end ? ' not' : ''} auto-renew on #{current_period_end}.",
          !subscription.cancel_at_period_end && with_unsubscribe ? "Send `unsubscribe #{subscription.id}` to unsubscribe." : nil
        ].compact.join("\n")
      else
        "#{subscription.status.titleize} subscription created #{Time.at(subscription.created).strftime('%B %d, %Y')} to #{subscription.plan.name} (#{amount})."
      end
    end
  end

  def stripe_customer_invoices_info
    stripe_customer.invoices.map do |invoice|
      amount = ActiveSupport::NumberHelper.number_to_currency(invoice.amount_due.to_f / 100)
      "Invoice for #{amount} on #{Time.at(invoice.date).strftime('%B %d, %Y')}, #{invoice.paid ? 'paid' : 'unpaid'}."
    end
  end

  def stripe_customer_sources_info
    stripe_customer.sources.map do |source|
      "On file #{source.brand} #{source.object}, #{source.name} ending with #{source.last4}, expires #{source.exp_month}/#{source.exp_year}."
    end
  end

  def active_stripe_subscription?
    !active_stripe_subscription.nil?
  end

  def active_stripe_subscription
    return unless stripe_customer

    stripe_customer.subscriptions.detect do |subscription|
      subscription.status == 'active' && !subscription.cancel_at_period_end
    end
  end

  def tags
    [
      subscribed? ? 'subscribed' : 'trial',
      stripe_customer_id? ? 'paid' : nil
    ].compact
  end

  def ping_if_active!
    return unless active?

    ping!
  rescue Slack::Web::Api::Errors::SlackError => e
    logger.warn "Active team #{self} ping, #{e.message}."
    case e.message
    when 'account_inactive', 'invalid_auth'
      deactivate!
    end
  end

  private

  SUBSCRIBED_TEXT = <<~EOS.freeze
    Your team has been subscribed. Thank you!
    Follow https://twitter.com/playplayio for news and updates.
  EOS

  def make_message(message, gif_name = nil)
    gif = Giphy.random(gif_name) if gif_name && gifs?
    [message, gif].compact.join("\n")
  end

  def update_subscribed_at
    return unless subscribed? && subscribed_changed?

    self.subscribed_at = subscribed? ? DateTime.now.utc : nil
  end

  def subscribed!
    return unless subscribed? && subscribed_changed?

    inform! SUBSCRIBED_TEXT, 'thanks'
  end

  def bot_mention
    "<@#{bot_user_id || 'bot'}>"
  end

  def activated_text
    <<~EOS
      Welcome! Invite #{bot_mention} to a channel to get started.
    EOS
  end

  def activated!
    return unless active? && activated_user_id && bot_user_id
    return unless active_changed? || activated_user_id_changed?

    inform_activated!
  end

  def inform_activated!
    im = slack_client.conversations_open(users: activated_user_id.to_s)
    slack_client.chat_postMessage(
      text: activated_text,
      channel: im['channel']['id'],
      as_user: true
    )
  end
end
