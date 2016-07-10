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
    let!(:active_team_four_weeks_ago) { Fabricate(:team, created_at: 4.weeks.ago - 1.hour) }
    let!(:premium_team_a_month_ago) { Fabricate(:team, created_at: 1.month.ago, premium: true) }
    let(:teams) { [active_team, active_team_one_week_ago, active_team_four_weeks_ago, premium_team_a_month_ago] }
    before do
      allow(Team).to receive(:active).and_return(teams)
    end
    context '#deactivate_dead_teams!' do
      it 'deactivates teams inactive for two weeks' do
        expect(active_team).to_not receive(:inform!)
        expect(active_team_one_week_ago).to_not receive(:inform!)
        expect(active_team_four_weeks_ago).to receive(:inform!).with(SlackGamebot::App::DEAD_MESSAGE, 'dead').once
        expect(premium_team_a_month_ago).to_not receive(:inform!)
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
  end
end
