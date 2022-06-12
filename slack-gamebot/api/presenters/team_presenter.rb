module Api
  module Presenters
    module TeamPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      property :id, type: String, desc: 'Team ID.'
      property :team_id, type: String, desc: 'Slack team ID.'
      property :name, type: String, desc: 'Team name.'
      property :domain, type: String, desc: 'Team domain.'
      property :active, type: ::Grape::API::Boolean, desc: 'Team is active.'
      property :subscribed, type: ::Grape::API::Boolean, desc: 'Team is a subscriber.'
      property :gifs, type: ::Grape::API::Boolean, desc: 'Team loves animated GIFs.'
      property :aliases, type: Array, desc: 'Game aliases.'
      property :elo, type: Integer, desc: 'Base elo.'
      property :unbalanced, type: ::Grape::API::Boolean, desc: 'Permits unbalanced challenges.'
      property :created_at, type: DateTime, desc: 'Date/time when the team was created.'
      property :updated_at, type: DateTime, desc: 'Date/time when the team was accepted, declined or canceled.'

      link :challenges do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/challenges?team_id=#{represented.id}"
      end

      link :matches do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/matches?team_id=#{represented.id}"
      end

      link :seasons do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/seasons?team_id=#{represented.id}"
      end

      link :users do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/users?team_id=#{represented.id}"
      end

      link :captains do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/users?team_id=#{represented.id}&captain=true"
      end

      link :game do |opts|
        if represented.game_id
          request = Grape::Request.new(opts[:env])
          "#{request.base_url}/api/games/#{represented.game_id}"
        end
      end

      link :self do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/teams/#{id}"
      end
    end
  end
end
