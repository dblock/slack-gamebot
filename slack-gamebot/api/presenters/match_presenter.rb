module Api
  module Presenters
    module MatchPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      property :id, type: String, desc: 'Match ID.'
      property :tied, type: Boolean, desc: 'Match is a tie.'
      property :resigned, type: Boolean, desc: 'The loser resigned.'
      property :scores, type: Array, desc: 'Match scores.'
      property :created_at, type: DateTime, desc: 'Date/time when the match was created.'

      link :team do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/teams/#{represented.team.id}" if represented.team
      end

      link :challenge do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/challenges/#{represented.challenge.id}" if represented.challenge
      end

      link :winners do |opts|
        request = Grape::Request.new(opts[:env])
        represented.winners.map do |user|
          "#{request.base_url}/api/users/#{user.id}"
        end
      end

      link :losers do |opts|
        request = Grape::Request.new(opts[:env])
        represented.losers.map do |user|
          "#{request.base_url}/api/users/#{user.id}"
        end
      end

      link :self do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/matches/#{id}"
      end
    end
  end
end
