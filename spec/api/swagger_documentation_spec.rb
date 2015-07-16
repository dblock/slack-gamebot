require 'spec_helper'

describe Api do
  include Api::Test::EndpointTest

  context 'swagger root' do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end
    it 'documents root level apis' do
      expect(subject['apis'].map { |api| api['path'] }).to eq([
        '/users.{format}',
        '/challenges.{format}',
        '/matches.{format}',
        '/seasons.{format}',
        '/swagger_doc.{format}'
      ])
    end
  end

  context 'users' do
    subject do
      get '/swagger_doc/users'
      JSON.parse(last_response.body)
    end
    it 'documents users apis' do
      expect(subject['apis'].map { |api| api['path'] }).to eq([
        '/users/{id}.{format}',
        '/users.{format}'
      ])
    end
  end
end
