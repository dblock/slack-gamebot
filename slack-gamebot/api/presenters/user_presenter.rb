module Api
  module Presenters
    module UserPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      property :id, type: String, desc: 'User ID.'
      property :user_name, type: String, desc: 'User name.'
      property :wins, type: Integer, desc: 'Number of wins.'
      property :losses, type: Integer, desc: 'Number of losses.'
      property :elo, type: Integer, desc: 'Elo.'
      property :rank, type: Integer, desc: 'Rank.'
      property :registered, type: Boolean, desc: 'User registered or unregistered.'
      property :created_at, as: :registered_at, type: DateTime, desc: 'Date/time when the user has registered.'
      property :captain, type: Boolean, desc: 'Team captain.'

      link :team do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/teams/#{represented.team.id}" if represented.team
      end

      link :self do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/users/#{id}"
      end
    end
  end
end
