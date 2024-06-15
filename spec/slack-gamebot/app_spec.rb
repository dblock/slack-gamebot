require 'spec_helper'

describe SlackGamebot::App do
  subject do
    SlackGamebot::App.instance
  end

  describe '#instance' do
    it 'is an instance of the market app' do
      expect(subject).to be_a(SlackRubyBotServer::App)
      expect(subject).to be_an_instance_of(SlackGamebot::App)
    end
  end

  context 'teams' do
    let!(:active_team) { Fabricate(:team, created_at: Time.now.utc) }
    let!(:active_team_one_week_ago) { Fabricate(:team, created_at: 1.week.ago) }
    let!(:active_team_four_weeks_ago) { Fabricate(:team, created_at: 5.weeks.ago) }
    let!(:subscribed_team_a_month_ago) { Fabricate(:team, created_at: 1.month.ago, subscribed: true) }
    let(:teams) { [active_team, active_team_one_week_ago, active_team_four_weeks_ago, subscribed_team_a_month_ago] }

    before do
      allow(Team).to receive(:active).and_return(teams)
    end

    describe '#deactivate_dead_teams!' do
      it 'deactivates teams inactive for two weeks' do
        expect(active_team).not_to receive(:inform!)
        expect(active_team).not_to receive(:inform_admin!)
        expect(active_team_one_week_ago).not_to receive(:inform!)
        expect(active_team_one_week_ago).not_to receive(:inform_admin!)
        expect(active_team_four_weeks_ago).to receive(:deactivate!).and_call_original
        expect(subscribed_team_a_month_ago).not_to receive(:inform!)
        expect(subscribed_team_a_month_ago).not_to receive(:inform_admin!)
        subject.send(:deactivate_dead_teams!)
        expect(active_team.reload.active).to be true
        expect(active_team_one_week_ago.reload.active).to be true
        expect(active_team_four_weeks_ago.reload.active).to be false
        expect(subscribed_team_a_month_ago.reload.active).to be true
        expect_any_instance_of(Team).to receive(:inform!).with(SlackGamebot::App::DEAD_MESSAGE, 'dead').once
        expect_any_instance_of(Team).to receive(:inform_admin!).with(SlackGamebot::App::DEAD_MESSAGE, 'dead').once
        subject.send(:inform_dead_teams!)
      end
    end
  end

  context 'subscribed' do
    include_context 'stripe mock'
    let(:plan) { stripe_helper.create_plan(id: 'slack-playplay-yearly', amount: 2999, name: 'Plan') }
    let(:customer) { Stripe::Customer.create(source: stripe_helper.generate_card_token, plan: plan.id, email: 'foo@bar.com') }
    let!(:team) { Fabricate(:team, subscribed: true, stripe_customer_id: customer.id) }

    describe '#check_subscribed_teams!' do
      it 'ignores active subscriptions' do
        expect_any_instance_of(Team).not_to receive(:inform!)
        expect_any_instance_of(Team).not_to receive(:inform_admin!)
        subject.send(:check_subscribed_teams!)
      end

      it 'notifies past due subscription' do
        customer.subscriptions.data.first['status'] = 'past_due'
        expect(Stripe::Customer).to receive(:retrieve).and_return(customer)
        expect_any_instance_of(Team).to receive(:inform_admin!).with("Your subscription to Plan ($29.99) is past due. #{team.update_cc_text}")
        subject.send(:check_subscribed_teams!)
      end

      it 'notifies canceled subscription' do
        customer.subscriptions.data.first['status'] = 'canceled'
        expect(Stripe::Customer).to receive(:retrieve).and_return(customer)
        expect_any_instance_of(Team).to receive(:inform_admin!).with('Your subscription to Plan ($29.99) was canceled and your team has been downgraded. Thank you for being a customer!')
        subject.send(:check_subscribed_teams!)
        expect(team.reload.subscribed?).to be false
      end

      it 'notifies no active subscriptions' do
        customer.subscriptions.data = []
        expect(Stripe::Customer).to receive(:retrieve).and_return(customer)
        expect_any_instance_of(Team).to receive(:inform_admin!).with('Your subscription was canceled and your team has been downgraded. Thank you for being a customer!')
        subject.send(:check_subscribed_teams!)
        expect(team.reload.subscribed?).to be false
      end
    end
  end
end
