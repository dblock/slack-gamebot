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
end
