require 'spec_helper'

describe 'Subscribe', js: true, type: :feature do
  let!(:game) { Fabricate(:game, name: 'pong') }
  context 'without team_id' do
    before do
      visit '/upgrade'
    end
    it 'requires a team' do
      expect(find('#messages')).to have_text('Missing or invalid team ID and/or game.')
      find('#subscribe', visible: false)
    end
  end
  context 'without game' do
    let!(:team) { Fabricate(:team) }
    before do
      visit "/upgrade?team_id=#{team.team_id}"
    end
    it 'requires a game' do
      expect(find('#messages')).to have_text('Missing or invalid team ID and/or game.')
      find('#subscribe', visible: false)
    end
  end
  context 'for a premium team' do
    let!(:team) { Fabricate(:team, game: game, premium: true) }
    before do
      visit "/upgrade?team_id=#{team.team_id}&game=#{team.game.name}"
    end
    it 'displays an error' do
      expect(find('#messages')).to have_text("Team #{team.name} already has a premium #{team.game.name} subscription, thank you for your support.")
      find('#subscribe', visible: false)
    end
  end
  shared_examples 'upgrades to premium' do
    it 'upgrades to premium' do
      visit "/upgrade?team_id=#{team.team_id}&game=#{team.game.name}"
      expect(find('#messages')).to have_text("Upgrade team #{team.name} to premium #{team.game.name} for $29.99 a year!")
      find('#subscribe', visible: true)

      expect(Stripe::Customer).to receive(:create).and_return('id' => 'customer_id')

      find('#subscribeButton').click
      sleep 1

      expect_any_instance_of(Team).to receive(:inform!).with(Team::UPGRADED_TEXT, 'thanks')

      stripe_iframe = all('iframe[name=stripe_checkout_app]').last
      Capybara.within_frame stripe_iframe do
        page.find_field('Email').set 'foo@bar.com'
        page.find_field('Card number').set '4242 4242 4242 4242'
        page.find_field('MM / YY').set '12/42'
        page.find_field('CVC').set '123'
        find('button[type="submit"]').click
      end

      sleep 5

      expect(find('#messages')).to have_text("Team #{team.name} successfully upgraded to premium #{team.game.name}. Thank you for your support!")
      find('#subscribe', visible: false)

      team.reload
      expect(team.premium).to be true
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
      it_behaves_like 'upgrades to premium'
    end
    context 'a team with two games' do
      let!(:team) { Fabricate(:team, game: game) }
      let!(:team2) { Fabricate(:team, team_id: team.team_id, game: Fabricate(:game)) }
      it_behaves_like 'upgrades to premium'
    end
    context 'a second team with two games' do
      let!(:team2) { Fabricate(:team, game: Fabricate(:game)) }
      let!(:team) { Fabricate(:team, game: game, team_id: team2.team_id) }
      it_behaves_like 'upgrades to premium'
    end
    context 'with a coupon' do
      let!(:team) { Fabricate(:team, game: game) }
      it 'applies the coupon' do
        coupon = double(Stripe::Coupon, id: 'coupon-id', amount_off: 1200)
        expect(Stripe::Coupon).to receive(:retrieve).with('coupon-id').and_return(coupon)
        visit "/upgrade?team_id=#{team.team_id}&game=#{team.game.name}&coupon=coupon-id"
        expect(find('#messages')).to have_text("Upgrade team #{team.name} to premium #{team.game.name} for $17.99 for the first year and $29.99 thereafter with coupon coupon-id!")
        find('#subscribe', visible: true)

        expect(Stripe::Customer).to receive(:create).with(hash_including(coupon: 'coupon-id')).and_return('id' => 'customer_id')

        expect_any_instance_of(Team).to receive(:inform!).with(Team::UPGRADED_TEXT, 'thanks')

        find('#subscribeButton').click
        sleep 1

        stripe_iframe = all('iframe[name=stripe_checkout_app]').last
        Capybara.within_frame stripe_iframe do
          page.find_field('Email').set 'foo@bar.com'
          page.find_field('Card number').set '4242 4242 4242 4242'
          page.find_field('MM / YY').set '12/42'
          page.find_field('CVC').set '123'
          find('button[type="submit"]').click
        end

        sleep 5

        expect(find('#messages')).to have_text("Team #{team.name} successfully upgraded to premium #{team.game.name}. Thank you for your support!")
        find('#subscribe', visible: false)

        team.reload
        expect(team.premium).to be true
        expect(team.stripe_customer_id).to eq 'customer_id'
      end
    end
  end
end
