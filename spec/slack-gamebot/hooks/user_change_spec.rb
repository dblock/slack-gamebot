require 'spec_helper'

describe SlackGamebot::Hooks::UserChange do
  let(:team) { Team.first || Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:client) { app.send(:client) }
  context 'with a user' do
    before do
      @user = Fabricate(:user)
    end
    it 'renames user' do
      app.send(:user_change, client, type: 'user_change', user: { id: @user.user_id, name: 'updated' })
      expect(@user.reload.user_name).to eq('updated')
    end
  end
end
