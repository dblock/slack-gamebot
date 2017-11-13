require 'spec_helper'

describe SlackGamebot::App do
  subject do
    SlackGamebot::App.instance
  end
  context '#instance' do
    it 'is an instance of the market app' do
      expect(subject).to be_a_kind_of(SlackRubyBotServer::App)
      expect(subject).to be_an_instance_of(SlackGamebot::App)
    end
  end
  context 'teams' do
    let!(:active_team) { Fabricate(:team, created_at: Time.now.utc) }
    let!(:active_team_one_week_ago) { Fabricate(:team, created_at: 1.week.ago) }
    let!(:active_team_four_weeks_ago) { Fabricate(:team, created_at: 5.weeks.ago) }
    let!(:premium_team_a_month_ago) { Fabricate(:team, created_at: 1.month.ago, premium: true) }
    let(:teams) { [active_team, active_team_one_week_ago, active_team_four_weeks_ago, premium_team_a_month_ago] }
    before do
      allow(Team).to receive(:active).and_return(teams)
    end
    context '#deactivate_dead_teams!' do
      it 'deactivates teams inactive for two weeks' do
        expect(active_team).to_not receive(:inform!)
        expect(active_team).to_not receive(:inform_admins!)
        expect(active_team_one_week_ago).to_not receive(:inform!)
        expect(active_team_one_week_ago).to_not receive(:inform_admins!)
        expect(active_team_four_weeks_ago).to receive(:inform!).with(SlackGamebot::App::DEAD_MESSAGE, 'dead').once
        expect(active_team_four_weeks_ago).to receive(:inform_admins!).with(SlackGamebot::App::DEAD_MESSAGE, 'dead').once
        expect(premium_team_a_month_ago).to_not receive(:inform!)
        expect(premium_team_a_month_ago).to_not receive(:inform_admins!)
        subject.send(:deactivate_dead_teams!)
        expect(active_team.reload.active).to be true
        expect(active_team_one_week_ago.reload.active).to be true
        expect(active_team_four_weeks_ago.reload.active).to be false
        expect(premium_team_a_month_ago.reload.active).to be true
      end
    end
    context '#nudge_sleeping_teams!' do
      it 'deactivates teams inactive for two weeks' do
        expect(active_team).to_not receive(:nudge!)
        expect(active_team_one_week_ago).to_not receive(:nudge!)
        expect(active_team_four_weeks_ago).to receive(:nudge!)
        expect(premium_team_a_month_ago).to receive(:nudge!)
        subject.send(:nudge_sleeping_teams!)
      end
    end
    context '#bother_free_teams!' do
      it 'bothers free teams' do
        expect(active_team).to_not receive(:bother!)
        expect(active_team_one_week_ago).to receive(:bother!).with("Enjoying this free bot? Don't be cheap! #{active_team_one_week_ago.upgrade_text}")
        expect(active_team_four_weeks_ago).to receive(:bother!).with("Enjoying this free bot? Don't be cheap! #{active_team_four_weeks_ago.upgrade_text}")
        expect(premium_team_a_month_ago).to_not receive(:bother!)
        subject.send(:bother_free_teams!)
      end
    end
  end
  context 'subscribed' do
    include_context :stripe_mock
    let(:plan) { stripe_helper.create_plan(id: 'slack-playplay-yearly', amount: 2999) }
    let(:customer) { Stripe::Customer.create(source: stripe_helper.generate_card_token, plan: plan.id, email: 'foo@bar.com') }
    let!(:team) { Fabricate(:team, premium: true, stripe_customer_id: customer.id) }
    context '#check_premium_teams!' do
      it 'ignores active subscriptions' do
        expect_any_instance_of(Team).to_not receive(:inform!)
        expect_any_instance_of(Team).to_not receive(:inform_admins!)
        subject.send(:check_premium_teams!)
      end
      it 'notifies past due subscription' do
        customer.subscriptions.data.first['status'] = 'past_due'
        expect(Stripe::Customer).to receive(:retrieve).and_return(customer)
        expect_any_instance_of(Team).to receive(:inform_admins!).with("Your premium subscription to StripeMock Default Plan ID ($29.99) is past due. #{team.update_cc_text}")
        subject.send(:check_premium_teams!)
      end
      it 'notifies past due subscription' do
        customer.subscriptions.data.first['status'] = 'canceled'
        expect(Stripe::Customer).to receive(:retrieve).and_return(customer)
        expect_any_instance_of(Team).to receive(:inform_admins!).with('Your premium subscription to StripeMock Default Plan ID ($29.99) was canceled and your team has been downgraded. Thank you for being a customer!')
        subject.send(:check_premium_teams!)
        expect(team.reload.premium?).to be false
      end
    end
  end
end
