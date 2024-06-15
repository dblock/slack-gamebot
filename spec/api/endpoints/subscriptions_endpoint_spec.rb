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

    context 'subscribed team' do
      let!(:team) { Fabricate(:team, subscribed: true) }

      it 'fails to create a subscription' do
        expect do
          client.subscriptions._post(
            team_id: team._id,
            stripe_token: 'token',
            stripe_token_type: 'card',
            stripe_email: 'foo@bar.com'
          )
        end.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Already a Subscriber'
        end
      end
    end

    context 'team with a canceled subscription' do
      let!(:team) { Fabricate(:team, subscribed: false, stripe_customer_id: 'customer_id') }
      let(:stripe_customer) { double(Stripe::Customer) }

      before do
        allow(Stripe::Customer).to receive(:retrieve).with(team.stripe_customer_id).and_return(stripe_customer)
      end

      context 'with an active subscription' do
        before do
          allow(stripe_customer).to receive(:subscriptions).and_return([
                                                                         double(Stripe::Subscription)
                                                                       ])
        end

        it 'fails to create a subscription' do
          expect do
            client.subscriptions._post(
              team_id: team._id,
              stripe_token: 'token',
              stripe_token_type: 'card',
              stripe_email: 'foo@bar.com'
            )
          end.to raise_error Faraday::ClientError do |e|
            json = JSON.parse(e.response[:body])
            expect(json['error']).to eq 'Existing Subscription Already Active'
          end
        end
      end

      context 'without no active subscription' do
        before do
          allow(stripe_customer).to receive(:subscriptions).and_return([])
        end

        it 'updates a subscription' do
          expect(Stripe::Customer).to receive(:update).with(
            team.stripe_customer_id,
            {
              source: 'token',
              plan: 'slack-playplay-yearly',
              email: 'foo@bar.com',
              coupon: nil,
              metadata: {
                id: team._id.to_s,
                team_id: team.team_id,
                name: team.name,
                domain: team.domain,
                game: team.game.name
              }
            }
          ).and_return('id' => 'customer_id')
          expect_any_instance_of(Team).to receive(:inform!).once
          client.subscriptions._post(
            team_id: team._id,
            stripe_token: 'token',
            stripe_token_type: 'card',
            stripe_email: 'foo@bar.com'
          )
          team.reload
          expect(team.subscribed).to be true
          expect(team.subscribed_at).not_to be_nil
          expect(team.stripe_customer_id).to eq 'customer_id'
        end
      end
    end

    context 'existing team' do
      include_context 'stripe mock'
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
          expect(team.subscribed).to be true
          expect(team.stripe_customer_id).not_to be_blank
          customer = Stripe::Customer.retrieve(team.stripe_customer_id)
          expect(customer).not_to be_nil
          expect(customer.metadata.to_h).to eq(
            id: team._id.to_s,
            name: team.name,
            team_id: team.team_id,
            domain: team.domain,
            game: team.game.name
          )
          expect(customer.discount).to be_nil
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
          expect(team.subscribed).to be true
          expect(team.stripe_customer_id).not_to be_blank
          customer = Stripe::Customer.retrieve(team.stripe_customer_id)
          expect(customer).not_to be_nil
          subscriptions = customer.subscriptions
          expect(subscriptions.count).to eq 1
          discount = customer.discount
          expect(discount.coupon.id).to eq 'slack-playplay-yearly-twenty-nine-ninety-nine'
        end
      end
    end
  end
end
