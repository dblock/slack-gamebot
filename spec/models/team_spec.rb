require 'spec_helper'

describe Team do
  context '#find_or_create_from_env!' do
    before do
      ENV['SLACK_API_TOKEN'] = 'token'
      ENV['GAMEBOT_SECRET'] = 'secret'
    end
    context 'team', vcr: { cassette_name: 'team_info' } do
      it 'creates a team' do
        expect { Team.find_or_create_from_env! }.to change(Team, :count).by(1)
        team = Team.first
        expect(team.team_id).to eq 'T04KB5WQH'
        expect(team.name).to eq 'dblock'
        expect(team.domain).to eq 'dblockdotorg'
        expect(team.secret).to eq 'secret'
        expect(team.token).to eq 'token'
      end
    end
    after do
      ENV.delete 'SLACK_API_TOKEN'
      ENV.delete 'GAMEBOT_SECRET'
    end
  end
end
