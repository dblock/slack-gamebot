require 'spec_helper'

describe SlackGamebot::Commands::Subscription, vcr: { cassette_name: 'user_info' } do
  let(:app) { SlackGamebot::Server.new(team:) }
  let(:client) { app.send(:client) }
  shared_examples_for 'subscription' do
    context 'on trial' do
      before do
        team.update_attributes!(subscribed: false, subscribed_at: nil)
      end
      it 'displays subscribe message' do
        expect(message: "#{SlackRubyBot.config.user} subscription").to respond_with_slack_message team.trial_message
      end
    end
    context 'with subscribed_at' do
      it 'displays subscription info' do
        customer_info = "Subscriber since #{team.subscribed_at.strftime('%B %d, %Y')}."
        expect(message: "#{SlackRubyBot.config.user} subscription").to respond_with_slack_message customer_info
      end
    end
    context 'with a plan' do
      include_context :stripe_mock
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
        before do
          team.update_attributes!(subscribed: true, stripe_customer_id: customer['id'])
        end
        it 'displays subscription info' do
          card = customer.sources.first
          current_period_end = Time.at(customer.subscriptions.first.current_period_end).strftime('%B %d, %Y')
          customer_info = [
            "Customer since #{Time.at(customer.created).strftime('%B %d, %Y')}.",
            "Subscribed to Plan ($29.99), will auto-renew on #{current_period_end}.",
            "On file Visa card, #{card.name} ending with #{card.last4}, expires #{card.exp_month}/#{card.exp_year}.",
            team.update_cc_text
          ].join("\n")
          expect(message: "#{SlackRubyBot.config.user} subscription").to respond_with_slack_message customer_info
        end
      end
    end
  end
  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true) }
    it_behaves_like 'subscription'
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      it_behaves_like 'subscription'
    end
  end
end
