module SlackGamebot
  module Commands
    class Subscription < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Subscription

      subscribed_command 'subscription' do |client, data, _match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        customer = Stripe::Customer.retrieve(client.owner.stripe_customer_id)
        customer_info = "Customer since #{Time.at(customer.created).strftime('%B %d, %Y')}."
        customer.subscriptions.each do |subscription|
          customer_info += "\nSubscribed to #{subscription.plan.name} (#{ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)})"
        end
        if user.captain?
          customer.invoices.each do |invoice|
            customer_info += "\nInvoice for #{ActiveSupport::NumberHelper.number_to_currency(invoice.amount_due.to_f / 100)} on #{Time.at(invoice.date).strftime('%B %d, %Y')}, #{invoice.paid ? 'paid' : 'unpaid'}."
          end
          customer.sources.each do |source|
            customer_info += "\nOn file #{source.brand} #{source.object}, #{source.name} ending with #{source.last4}, expires #{source.exp_month}/#{source.exp_year}."
          end
          customer_info += "\n#{client.owner.update_cc_text}"
        end
        client.say(channel: data.channel, text: customer_info)
        logger.info "PREMIUM: #{client.owner} - #{data.user}"
      end
    end
  end
end
