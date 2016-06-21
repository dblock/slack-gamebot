require 'spec_helper'

describe Api do
  include Api::Test::EndpointTest

  context 'swagger root' do
    subject do
      get '/api/swagger_doc'
      JSON.parse(last_response.body)
    end
    it 'documents root level apis' do
      expect(subject['paths'].keys).to eq [
        '/api/status',
        '/api/users/{id}',
        '/api/users',
        '/api/challenges/{id}',
        '/api/challenges',
        '/api/matches/{id}',
        '/api/matches',
        '/api/seasons/current',
        '/api/seasons/{id}',
        '/api/seasons',
        '/api/teams/{id}',
        '/api/teams',
        '/api/games/{id}',
        '/api/games',
        '/api/subscriptions'
      ]
    end
  end

  context 'users' do
    subject do
      get '/api/swagger_doc/users'
      JSON.parse(last_response.body)
    end
    it 'documents users apis' do
      expect(subject['paths'].keys).to eq [
        '/api/users/{id}',
        '/api/users'
      ]
    end
  end
end
