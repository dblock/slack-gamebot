require 'spec_helper'

describe Team do
  let!(:game) { Fabricate(:game) }
  context '#find_or_create_from_env!' do
    before do
      ENV['SLACK_API_TOKEN'] = 'token'
    end
    context 'team', vcr: { cassette_name: 'team_info' } do
      it 'creates a team' do
        expect { Team.find_or_create_from_env! }.to change(Team, :count).by(1)
        team = Team.first
        expect(team.team_id).to eq 'T04KB5WQH'
        expect(team.name).to eq 'dblock'
        expect(team.domain).to eq 'dblockdotorg'
        expect(team.token).to eq 'token'
        expect(team.game).to eq game
      end
    end
    after do
      ENV.delete 'SLACK_API_TOKEN'
    end
  end
  context '#destroy' do
    let!(:team) { Fabricate(:team) }
    let!(:match) { Fabricate(:match, team: team) }
    let!(:season) { Fabricate(:season, team: team) }
    it 'destroys dependent records' do
      expect(Team.count).to eq 1
      expect(User.count).to eq 2
      expect(Challenge.count).to eq 1
      expect(Match.count).to eq 1
      expect(Season.count).to eq 1
      expect do
        expect do
          expect do
            expect do
              expect do
                team.destroy
              end.to change(Team, :count).by(-1)
            end.to change(User, :count).by(-2)
          end.to change(Challenge, :count).by(-1)
        end.to change(Match, :count).by(-1)
      end.to change(Season, :count).by(-1)
    end
  end
  context '#purge!' do
    let!(:active_team) { Fabricate(:team) }
    let!(:inactive_team) { Fabricate(:team, active: false) }
    let!(:inactive_team_a_week_ago) { Fabricate(:team, updated_at: 1.week.ago, active: false) }
    let!(:inactive_team_two_weeks_ago) { Fabricate(:team, updated_at: 2.weeks.ago, active: false) }
    let!(:inactive_team_a_month_ago) { Fabricate(:team, updated_at: 1.month.ago, active: false) }
    it 'destroys teams inactive for two weeks' do
      expect do
        Team.purge!
      end.to change(Team, :count).by(-2)
      expect(Team.find(active_team.id)).to eq active_team
      expect(Team.find(inactive_team.id)).to eq inactive_team
      expect(Team.find(inactive_team_a_week_ago.id)).to eq inactive_team_a_week_ago
      expect(Team.find(inactive_team_two_weeks_ago.id)).to be nil
      expect(Team.find(inactive_team_a_month_ago.id)).to be nil
    end
  end
  context '#dead? and #asleep?' do
    context 'default' do
      let(:team) { Fabricate(:team) }
      it 'false' do
        expect(team.asleep?).to be false
        expect(team.dead?).to be false
      end
    end
    context 'team created three weeks ago' do
      let(:team) { Fabricate(:team, created_at: 3.weeks.ago) }
      it 'dead=false' do
        expect(team.asleep?).to be true
        expect(team.dead?).to be false
      end
      context 'with a recent challenge' do
        let!(:challenge) { Fabricate(:challenge, team: team) }
        it 'false' do
          expect(team.asleep?).to be false
          expect(team.dead?).to be false
        end
      end
      context 'with a recent match' do
        let!(:match) { Fabricate(:match, team: team) }
        it 'false' do
          expect(team.asleep?).to be false
          expect(team.dead?).to be false
        end
      end
      context 'with a recent match lost to' do
        let!(:match) { Fabricate(:match_lost_to, team: team) }
        it 'false' do
          expect(team.asleep?).to be false
          expect(team.dead?).to be false
        end
      end
      context 'with an old challenge' do
        let!(:challenge) { Fabricate(:challenge, updated_at: 3.weeks.ago, team: team) }
        it 'true' do
          expect(team.asleep?).to be true
          expect(team.dead?).to be false
        end
      end
    end
    context 'team created over a month ago' do
      let(:team) { Fabricate(:team, created_at: 32.days.ago) }
      it 'dead=true' do
        expect(team.dead?).to be true
      end
      context 'with a recent challenge' do
        let!(:challenge) { Fabricate(:challenge, updated_at: 2.weeks.ago, team: team) }
        it 'true' do
          expect(team.dead?).to be false
        end
      end
      context 'with an old challenge' do
        let!(:challenge) { Fabricate(:challenge, updated_at: 5.weeks.ago, team: team) }
        it 'true' do
          expect(team.dead?).to be true
        end
      end
    end
  end
  context 'gifs' do
    let!(:team) { Fabricate(:team) }
    context 'with a played challenge' do
      let(:challenge) { Fabricate(:played_challenge) }
      context 'with a new challenge' do
        let!(:open_challenge) { Fabricate(:challenge, challengers: challenge.challengers, challenged: challenge.challenged) }
        it 'can be set' do
          expect(team.challenges.detect { |c| !c.valid? }).to be nil
          expect { team.update_attributes!(gifs: !team.gifs) }.to_not raise_error
        end
      end
    end
  end
  context 'subscribed states' do
    let(:today) { DateTime.parse('2018/7/15 12:42pm') }
    let(:subscribed_team) { Fabricate(:team, subscribed: true) }
    let(:team_created_today) { Fabricate(:team, created_at: today) }
    let(:team_created_1_week_ago) { Fabricate(:team, created_at: (today - 1.week)) }
    let(:team_created_3_weeks_ago) { Fabricate(:team, created_at: (today - 3.weeks)) }
    before do
      Timecop.travel(today + 1.day)
    end
    it 'subscription_expired?' do
      expect(subscribed_team.subscription_expired?).to be false
      expect(team_created_1_week_ago.subscription_expired?).to be false
      expect(team_created_3_weeks_ago.subscription_expired?).to be true
    end
    it 'trial_ends_at' do
      expect { subscribed_team.trial_ends_at }.to raise_error 'Team is subscribed.'
      expect(team_created_today.trial_ends_at).to eq team_created_today.created_at + 2.weeks
      expect(team_created_1_week_ago.trial_ends_at).to eq team_created_1_week_ago.created_at + 2.weeks
      expect(team_created_3_weeks_ago.trial_ends_at).to eq team_created_3_weeks_ago.created_at + 2.weeks
    end
    it 'remaining_trial_days' do
      expect { subscribed_team.remaining_trial_days }.to raise_error 'Team is subscribed.'
      expect(team_created_today.remaining_trial_days).to eq 13
      expect(team_created_1_week_ago.remaining_trial_days).to eq 6
      expect(team_created_3_weeks_ago.remaining_trial_days).to eq 0
    end
    context '#inform_trial!' do
      it 'subscribed' do
        expect(subscribed_team).to_not receive(:inform!)
        expect(subscribed_team).to_not receive(:inform_admin!)
        subscribed_team.inform_trial!
      end
      it '1 week ago' do
        expect(team_created_1_week_ago).to receive(:inform!).with(
          "Your trial subscription expires in 6 days. #{team_created_1_week_ago.subscribe_text}"
        )
        expect(team_created_1_week_ago).to receive(:inform_admin!).with(
          "Your trial subscription expires in 6 days. #{team_created_1_week_ago.subscribe_text}"
        )
        team_created_1_week_ago.inform_trial!
      end
      it 'expired' do
        expect(team_created_3_weeks_ago).to_not receive(:inform!)
        expect(team_created_3_weeks_ago).to_not receive(:inform_admin!)
        team_created_3_weeks_ago.inform_trial!
      end
      it 'informs once' do
        expect(team_created_1_week_ago).to receive(:inform!).once
        expect(team_created_1_week_ago).to receive(:inform_admin!).once
        2.times { team_created_1_week_ago.inform_trial! }
      end
    end
    after do
      Timecop.return
    end
  end
  context '#inform!' do
    let(:team) { Fabricate(:team) }
    before do
      team.bot_user_id = 'bot_user_id'
    end
    it 'sends message to all channels', vcr: { cassette_name: 'users_conversations' } do
      expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).exactly(25).times.and_return('ts' => '1503435956.000247')
      team.inform!(message: 'message')
    end
  end
  context '#activated' do
    pending 'DMs installing user when activated'
  end
end
