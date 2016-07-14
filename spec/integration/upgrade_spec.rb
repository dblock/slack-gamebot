require 'spec_helper'

describe 'Subscribe', js: true, type: :feature do
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
    let!(:team) { Fabricate(:team, premium: true) }
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
        page.execute_script("$('input#email').val('foo@bar.com');")
        page.execute_script("$('input#card_number').val('4242 4242 4242 4242');")
        page.execute_script("$('input#cc-exp').val('12/16');")
        page.execute_script("$('input#cc-csc').val('123');")
        page.execute_script("$('#submitButton').click();")
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
      let!(:team) { Fabricate(:team) }
      it_behaves_like 'upgrades to premium'
    end
    context 'a team with two games' do
      let!(:team) { Fabricate(:team) }
      let!(:team2) { Fabricate(:team, team_id: team.team_id, game: Fabricate(:game)) }
      it_behaves_like 'upgrades to premium'
    end
    context 'a second team with two games' do
      let!(:team2) { Fabricate(:team) }
      let!(:team) { Fabricate(:team, team_id: team2.team_id, game: Fabricate(:game)) }
      it_behaves_like 'upgrades to premium'
    end
    context 'with a coupon' do
      let!(:team) { Fabricate(:team) }
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
          page.execute_script("$('input#email').val('foo@bar.com');")
          page.execute_script("$('input#card_number').val('4242 4242 4242 4242');")
          page.execute_script("$('input#cc-exp').val('12/16');")
          page.execute_script("$('input#cc-csc').val('123');")
          page.execute_script("$('#submitButton').click();")
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
