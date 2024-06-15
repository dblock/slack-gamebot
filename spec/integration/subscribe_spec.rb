require 'spec_helper'

describe 'Subscribe', :js, type: :feature do
  let!(:game) { Fabricate(:game, name: 'pong') }

  context 'without team_id' do
    before do
      visit '/subscribe'
    end

    it 'requires a team' do
      expect(find_by_id('messages')).to have_text('Missing or invalid team ID and/or game.')
      find_by_id('subscribe', visible: false)
    end
  end

  context 'without game' do
    let!(:team) { Fabricate(:team) }

    before do
      visit "/subscribe?team_id=#{team.team_id}"
    end

    it 'requires a game' do
      expect(find_by_id('messages')).to have_text('Missing or invalid team ID and/or game.')
      find_by_id('subscribe', visible: false)
    end
  end

  context 'for a subscribed team' do
    let!(:team) { Fabricate(:team, game: game, subscribed: true) }

    before do
      visit "/subscribe?team_id=#{team.team_id}&game=#{team.game.name}"
    end

    it 'displays an error' do
      expect(find_by_id('messages')).to have_text("Team #{team.name} is already subscribed to #{team.game.name}, thank you.")
      find_by_id('subscribe', visible: false)
    end
  end

  shared_examples 'subscribes' do
    it 'subscribes' do
      visit "/subscribe?team_id=#{team.team_id}&game=#{team.game.name}"
      expect(find_by_id('messages')).to have_text("Subscribe team #{team.name} to #{team.game.name} for $29.99 a year!")
      find_by_id('subscribe', visible: true)

      expect(Stripe::Customer).to receive(:create).and_return('id' => 'customer_id')

      find_by_id('subscribeButton').click
      sleep 1

      expect_any_instance_of(Team).to receive(:inform!).with(Team::SUBSCRIBED_TEXT, 'thanks')

      stripe_iframe = all('iframe[name=stripe_checkout_app]').last
      Capybara.within_frame stripe_iframe do
        page.find_field('Email').set 'foo@bar.com'
        page.find_field('Card number').client_set '4242 4242 4242 4242'
        page.find_field('MM / YY').client_set '12/42'
        page.find_field('CVC').set '123'
        find('button[type="submit"]').click
      end

      sleep 5

      expect(find_by_id('messages')).to have_text("Team #{team.name} successfully subscribed to #{team.game.name}.\nThank you!")
      find_by_id('subscribe', visible: false)

      team.reload
      expect(team.subscribed).to be true
      expect(team.stripe_customer_id).to eq 'customer_id'
    end
  end

  context 'with a stripe key' do
    before do
      ENV['STRIPE_API_PUBLISHABLE_KEY'] = 'pk_test_804U1vUeVeTxBl8znwriXskf'
    end

    after do
      ENV.delete 'STRIPE_API_PUBLISHABLE_KEY'
    end

    context 'a team' do
      let!(:team) { Fabricate(:team, game: game) }

      it_behaves_like 'subscribes'
    end

    context 'a team with two games' do
      let!(:team) { Fabricate(:team, game: game) }
      let!(:team2) { Fabricate(:team, team_id: team.team_id, game: Fabricate(:game)) }

      it_behaves_like 'subscribes'
    end

    context 'a second team with two games' do
      let!(:team2) { Fabricate(:team, game: Fabricate(:game)) }
      let!(:team) { Fabricate(:team, game: game, team_id: team2.team_id) }

      it_behaves_like 'subscribes'
    end

    context 'with a coupon' do
      let!(:team) { Fabricate(:team, game: game) }

      it 'applies the coupon' do
        coupon = double(Stripe::Coupon, id: 'coupon-id', amount_off: 1200)
        expect(Stripe::Coupon).to receive(:retrieve).with('coupon-id').and_return(coupon)
        visit "/subscribe?team_id=#{team.team_id}&game=#{team.game.name}&coupon=coupon-id"
        expect(find_by_id('messages')).to have_text("Subscribe team #{team.name} to #{team.game.name} for $17.99 for the first year and $29.99 thereafter with coupon coupon-id!")
        find_by_id('subscribe', visible: true)

        expect(Stripe::Customer).to receive(:create).with(hash_including(coupon: 'coupon-id')).and_return('id' => 'customer_id')

        expect_any_instance_of(Team).to receive(:inform!).with(Team::SUBSCRIBED_TEXT, 'thanks')

        find_by_id('subscribeButton').click
        sleep 1

        stripe_iframe = all('iframe[name=stripe_checkout_app]').last
        Capybara.within_frame stripe_iframe do
          page.find_field('Email').set 'foo@bar.com'
          page.find_field('Card number').client_set '4242 4242 4242 4242'
          page.find_field('MM / YY').client_set '12/42'
          page.find_field('CVC').set '123'
          find('button[type="submit"]').click
        end

        sleep 5

        expect(find_by_id('messages')).to have_text("Team #{team.name} successfully subscribed to #{team.game.name}.\nThank you!")
        find_by_id('subscribe', visible: false)

        team.reload
        expect(team.subscribed).to be true
        expect(team.stripe_customer_id).to eq 'customer_id'
      end
    end
  end
end
