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
            team_id: team.team_id,
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
            team_id: team.team_id,
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
      let!(:team) { Fabricate(:team) }
      it 'creates a subscription' do
        expect(Stripe::Customer).to receive(:create).with(
          source: 'token',
          plan: 'slack-playplay-yearly',
          email: 'foo@bar.com',
          metadata: {
            id: team._id,
            team_id: team.team_id,
            name: team.name,
            domain: team.domain
          }
        ).and_return('id' => 'customer_id')
        client.subscriptions._post(
          team_id: team.team_id,
          stripe_token: 'token',
          stripe_token_type: 'card',
          stripe_email: 'foo@bar.com'
        )
        team.reload
        expect(team.premium).to be true
        expect(team.stripe_customer_id).to eq 'customer_id'
      end
    end
  end
end
