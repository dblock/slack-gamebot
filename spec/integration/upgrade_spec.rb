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
  context 'for a team' do
    let!(:team) { Fabricate(:team) }
    before do
      ENV['STRIPE_API_PUBLISHABLE_KEY'] = 'pk_test_804U1vUeVeTxBl8znwriXskf'
    end
    after do
      ENV.delete 'STRIPE_API_PUBLISHABLE_KEY'
    end
    it 'upgrades to premium' do
      visit "/upgrade?team_id=#{team.team_id}&game=#{team.game.name}"
      expect(find('#messages')).to have_text("Upgrade team #{team.name} to premium #{team.game.name} for $29.99 a year!")
      find('#subscribe', visible: true)

      expect(Stripe::Customer).to receive(:create).and_return('id' => 'customer_id')

      find('#subscribeButton').click
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
