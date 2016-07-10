require 'spec_helper'

describe Api::Endpoints::SubscriptionsEndpoint do
  include Api::Test::EndpointTest

  context 'subcriptions' do
    it 'requires stripe parameters' do
      expect { client.subscriptions._post }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['message']).to eq 'Invalid parameters.'
        expect(json['type']).to eq 'param_error'
      end
    end
    context 'premium team' do
      let!(:team) { Fabricate(:team, premium: true, stripe_customer_id: 'customer_id') }
      it 'fails to create a subscription' do
        expect do
          client.subscriptions._post(
            team_id: team._id,
            stripe_token: 'token',
            stripe_token_type: 'card',
            stripe_email: 'foo@bar.com')
        end.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Already a Premium Subscription'
        end
      end
    end
    context 'non-premium team with a customer_id' do
      let!(:team) { Fabricate(:team, stripe_customer_id: 'customer_id') }
      it 'fails to create a subscription' do
        expect do
          client.subscriptions._post(
            team_id: team._id,
            stripe_token: 'token',
            stripe_token_type: 'card',
            stripe_email: 'foo@bar.com')
        end.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Customer Already Registered'
        end
      end
    end
    context 'existing team' do
      include_context :stripe_mock
      let!(:team) { Fabricate(:team) }
      context 'with a plan' do
        before do
          expect_any_instance_of(Team).to receive(:inform!).once
          stripe_helper.create_plan(id: 'slack-playplay-yearly', amount: 2999)
          client.subscriptions._post(
            team_id: team._id,
            stripe_token: stripe_helper.generate_card_token,
            stripe_token_type: 'card',
            stripe_email: 'foo@bar.com'
          )
          team.reload
        end
        it 'creates a subscription' do
          expect(team.premium).to be true
          expect(team.stripe_customer_id).to_not be_blank
          customer = Stripe::Customer.retrieve(team.stripe_customer_id)
          expect(customer).to_not be nil
          expect(Hash[customer.metadata]).to eq(
            id: team._id.to_s,
            name: team.name,
            team_id: team.team_id,
            domain: team.domain,
            game: team.game.name
          )
          expect(customer.discount).to be nil
          subscriptions = customer.subscriptions
          expect(subscriptions.count).to eq 1
        end
      end
      context 'with a coupon' do
        before do
          expect_any_instance_of(Team).to receive(:inform!).once
          stripe_helper.create_plan(id: 'slack-playplay-yearly', amount: 2999)
          stripe_helper.create_coupon(id: 'slack-playplay-yearly-twenty-nine-ninety-nine', amount_off: 2999)
          client.subscriptions._post(
            team_id: team._id,
            stripe_token: stripe_helper.generate_card_token,
            stripe_token_type: 'card',
            stripe_email: 'foo@bar.com',
            stripe_coupon: 'slack-playplay-yearly-twenty-nine-ninety-nine'
          )
          team.reload
        end
        it 'creates a subscription' do
          expect(team.premium).to be true
          expect(team.stripe_customer_id).to_not be_blank
          customer = Stripe::Customer.retrieve(team.stripe_customer_id)
          expect(customer).to_not be nil
          subscriptions = customer.subscriptions
          expect(subscriptions.count).to eq 1
          discount = customer.discount
          expect(discount.coupon.id).to eq 'slack-playplay-yearly-twenty-nine-ninety-nine'
        end
      end
    end
  end
end
