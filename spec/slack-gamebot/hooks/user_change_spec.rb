require 'spec_helper'

describe SlackGamebot::Hooks::UserChange do
  let(:app) { SlackGamebot::Server.new }
  context 'with a user' do
    before do
      @user = Fabricate(:user)
    end
    it 'renames user' do
      app.send(:user_change, nil, type: 'user_change', user: { id: @user.user_id, name: 'updated' })
      expect(@user.reload.user_name).to eq('updated')
    end
  end
end
