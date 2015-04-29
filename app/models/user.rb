class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :user_name, type: String

  index({ user_id: 1, team_id: 1 }, unique: true, name: 'user_team_index')

  def slack_mention
    "<@#{user_id}>"
  end

  def self.find_by_slack_mention(user_name)
    User.where(user_name =~ /^<@(.*)>$/ ? { user_id: Regexp.last_match[1] } : { user_name: user_name }).first
  end

  # Find an existing record, update the username if necessary, otherwise create a user record.
  def self.find_create_or_update_by_slack_id!(slack_id)
    instance = User.where(user_id: slack_id).first
    instance_info = Hashie::Mash.new(Slack.users_info(user: slack_id)).user
    instance.update_attributes!(user_name: instance_info.name) if instance && instance.user_name != instance_info.name
    instance ||= User.create!(user_id: slack_id, user_name: instance_info.name)
    instance
  end
end
