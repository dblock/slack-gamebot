require 'spec_helper'

describe 'Update cc', js: true, type: :feature do
  let!(:game) { Fabricate(:game, name: 'pong') }

  shared_examples 'updates cc' do
    it 'updates cc' do
      visit "/update_cc?team_id=#{team.team_id}&game=#{team.game.name}"
      expect(find('h3')).to have_text('PLAYPLAY.IO: UPDATE CREDIT CARD INFO')

      customer = double
      expect(Stripe::Customer).to receive(:retrieve).and_return(customer)
      expect(customer).to receive(:source=)
      expect(customer).to receive(:save)

      click_button 'Update Credit Card'
      sleep 1
      stripe_iframe = all('iframe[name=stripe_checkout_app]').last
      Capybara.within_frame stripe_iframe do
        page.find_field('Email').set 'foo@bar.com'
        page.find_field('Card number').set '4012 8888 8888 1881'
        page.find_field('MM / YY').set '12/42'
        page.find_field('CVC').set '345'
        find('button[type="submit"]').click
      end

      sleep 5

      expect(find('#messages')).to have_text("Successfully updated team #{team.name} credit card for #{team.game.name}. Thank you for your support!")
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
      let!(:team) { Fabricate(:team, game: game, stripe_customer_id: 'stripe_customer_id') }
      it_behaves_like 'updates cc'
    end
  end unless ENV['CI'] # see https://github.com/dblock/slack-gamebot/issues/139
end
