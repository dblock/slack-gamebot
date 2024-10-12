require 'spec_helper'

describe SlackGamebot::Commands::Unsubscribe, vcr: { cassette_name: 'user_info' } do
  let(:app) { SlackGamebot::Server.new(team:) }
  let(:client) { app.send(:client) }

  shared_examples_for 'unsubscribe' do
    context 'on trial' do
      before do
        team.update_attributes!(subscribed: false, subscribed_at: nil)
      end

      it 'displays all set message' do
        expect(message: "#{SlackRubyBot.config.user} unsubscribe").to respond_with_slack_message "You don't have a paid subscription, all set."
      end
    end

    context 'with subscribed_at' do
      before do
        team.update_attributes!(subscribed: true, subscribed_at: 1.year.ago)
      end

      it 'displays subscription info' do
        expect(message: "#{SlackRubyBot.config.user} unsubscribe").to respond_with_slack_message "You don't have a paid subscription, all set."
      end
    end

    context 'with a plan' do
      include_context 'stripe mock'
      before do
        stripe_helper.create_plan(id: 'slack-playplay-yearly', amount: 2999, name: 'Plan')
      end

      context 'a customer' do
        let!(:customer) do
          Stripe::Customer.create(
            source: stripe_helper.generate_card_token,
            plan: 'slack-playplay-yearly',
            email: 'foo@bar.com'
          )
        end
        let(:active_subscription) { team.active_stripe_subscription }
        let(:current_period_end) { Time.at(active_subscription.current_period_end).strftime('%B %d, %Y') }

        before do
          team.update_attributes!(subscribed: true, stripe_customer_id: customer['id'])
        end

        it 'displays subscription info' do
          customer_info = [
            "Subscribed to Plan ($29.99), will auto-renew on #{current_period_end}.",
            "Send `unsubscribe #{active_subscription.id}` to unsubscribe."
          ].join("\n")
          expect(message: "#{SlackRubyBot.config.user} unsubscribe").to respond_with_slack_message customer_info
        end

        it 'cannot unsubscribe with an invalid subscription id' do
          expect(message: "#{SlackRubyBot.config.user} unsubscribe xyz").to respond_with_slack_message 'Sorry, I cannot find a subscription with "xyz".'
        end

        it 'unsubscribes' do
          expect(message: "#{SlackRubyBot.config.user} unsubscribe #{active_subscription.id}").to respond_with_slack_message 'Successfully canceled auto-renew for Plan ($29.99).'
          team.reload
          expect(team.subscribed).to be true
          expect(team.stripe_customer_id).not_to be_nil
        end
      end
    end
  end

  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true) }

    it_behaves_like 'unsubscribe'
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }

      it_behaves_like 'unsubscribe'
    end
  end
end
