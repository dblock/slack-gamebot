require 'spec_helper'

describe SlackGamebot::Commands::Subscription, vcr: { cassette_name: 'user_info' } do
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:client) { app.send(:client) }
  shared_examples_for 'subscription' do
    context 'manually subscribed' do
      before do
        team.update_attributes!(subscribed: true)
      end
      it 'displays subscription info' do
        customer_info = "Subscriber since #{team.subscribed_at.strftime('%B %d, %Y')}."
        expect(message: "#{SlackRubyBot.config.user} subscription").to respond_with_slack_message customer_info
      end
    end
    context 'with a plan' do
      include_context :stripe_mock
      before do
        stripe_helper.create_plan(id: 'slack-playplay-yearly', amount: 2999)
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
          customer_info = "Customer since #{Time.at(customer.created).strftime('%B %d, %Y')}."
          customer_info += "\nSubscribed to StripeMock Default Plan ID ($29.99)"
          card = customer.sources.first
          customer_info += "\nOn file Visa card, #{card.name} ending with #{card.last4}, expires #{card.exp_month}/#{card.exp_year}."
          customer_info += "\n#{team.update_cc_text}"
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
