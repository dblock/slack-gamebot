require 'spec_helper'

describe Api::UsersEndpoint do
  def app
    Api::Middleware.instance
  end

  let(:client) do
    Hyperclient.new('http://example.org') do |client|
      client.connection(default: false) do |conn|
        conn.request :json
        conn.response :json
        conn.use Faraday::Adapter::Rack, app
      end
    end
  end

  context 'users' do
    before do
      5.times { Fabricate(:user) }
    end

    it 'returns 3 users by default' do
      expect(client.users({}).count).to eq 3
    end

    it 'returns 2 users' do
      expect(client.users(size: 2).count).to eq 2
    end

    it 'returns pagination' do
      response = client.users(size: 2, page: 2)
      expect(response._links.next._url).to eq 'http://example.org/users?page=3&size=2'
      expect(response._links.prev._url).to eq 'http://example.org/users?page=1&size=2'
      expect(response._links.self._url).to eq 'http://example.org/users?page=2&size=2'
    end

    it 'returns all unique ids' do
      users = client.users({})
      expect(users.map(&:id).uniq.count).to eq 3
    end
  end

  context 'user' do
    let(:existing_user) { Fabricate(:user) }
    it 'returns a user' do
      user = client.user(id: existing_user.id)
      expect(user.id).to eq existing_user.id.to_s
      expect(user.user_name).to eq existing_user.user_name
    end
  end
end
