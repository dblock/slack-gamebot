require 'spec_helper'

describe Api::Endpoints::UsersEndpoint do
  include Api::Test::EndpointTest

  it_behaves_like 'a paginated api', User

  context 'user' do
    let(:existing_user) { Fabricate(:user) }
    it 'returns a user' do
      user = client.user(id: existing_user.id)
      expect(user.id).to eq existing_user.id.to_s
      expect(user.user_name).to eq existing_user.user_name
      expect(user._links.self._url).to eq "http://example.org/users/#{existing_user.id}"
    end
  end
end
