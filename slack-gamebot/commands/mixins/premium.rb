module SlackGamebot
  module Commands
    module Mixins
      module Premium
        extend ActiveSupport::Concern

        module ClassMethods
          def premium_command(*values, &_block)
            command(*values) do |client, data, match|
              if Stripe.api_key && !client.owner.reload.premium
                client.say channel: data.channel, text: client.owner.premium_text
                logger.info "#{client.owner}, user=#{data.user}, text=#{data.text}, premium feature required"
              else
                yield client, data, match
              end
            end
          end

          def premium(client, data, &_block)
            if Stripe.api_key && !client.owner.reload.premium
              client.say channel: data.channel, text: client.owner.premium_text
              logger.info "#{client.owner}, user=#{data.user}, text=#{data.text}, premium feature required"
            else
              yield
            end
          end
        end
      end
    end
  end
end
