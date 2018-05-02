module SlackGamebot
  module Commands
    module Mixins
      module Subscription
        extend ActiveSupport::Concern

        module ClassMethods
          def subscribed_command(*values, &_block)
            command(*values) do |client, data, match|
              if Stripe.api_key && client.owner.reload.subscripion_expired?
                client.say channel: data.channel, text: client.owner.subscribe_text
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
