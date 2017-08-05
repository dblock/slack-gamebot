require 'spec_helper'

describe SlackGamebot::Commands::Premium, vcr: { cassette_name: 'user_info' } do
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:client) { app.send(:client) }
  context 'team' do
    let!(:team) { Fabricate(:team) }
    it 'is a premium feature' do
      expect(message: "#{SlackRubyBot.config.user} premium", user: 'user').to respond_with_slack_message(
        "This is a premium feature. Upgrade your team to premium for $29.99 a year at https://www.playplay.io/upgrade?team_id=#{team.team_id}&game=#{team.game.name}."
      )
    end
  end
  shared_examples_for 'premium' do
    include_context :stripe_mock
    context 'with a plan' do
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
          team.update_attributes!(premium: true, stripe_customer_id: customer['id'])
        end
        it 'displays premium info' do
          customer_info = "Customer since #{Time.at(customer.created).strftime('%B %d, %Y')}."
          customer_info += "\nSubscribed to StripeMock Default Plan ID ($29.99)"
          card = customer.sources.first
          customer_info += "\nOn file Visa card, #{card.name} ending with #{card.last4}, expires #{card.exp_month}/#{card.exp_year}."
          customer_info += "\n#{team.update_cc_text}"
          expect(message: "#{SlackRubyBot.config.user} premium").to respond_with_slack_message customer_info
        end
      end
    end
  end
  context 'premium team' do
    let!(:team) { Fabricate(:team, premium: true) }
    it_behaves_like 'premium'
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      it_behaves_like 'premium'
    end
  end
end
