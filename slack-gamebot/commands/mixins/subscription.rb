module SlackGamebot
  module Commands
    module Mixins
      module Subscription
        extend ActiveSupport::Concern

        module ClassMethods
          def subscribed_command(*values, &_block)
            command(*values) do |client, data, match|
              if Stripe.api_key && client.owner.reload.subscription_expired?
                client.say channel: data.channel, text: client.owner.trial_message
                logger.info "#{client.owner}, user=#{data.user}, text=#{data.text}, subscribed feature required"
              else
                yield client, data, match
              end
            end
          end
        end
      end
    end
  end
end
