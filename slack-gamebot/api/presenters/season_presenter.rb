module Api
  module Presenters
    module SeasonPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      property :current_id, as: :id, type: String, desc: 'Season ID.'
      property :created_at, type: DateTime, desc: 'Date/time when the season was created.'

      collection :user_ranks, extend: UserRankPresenter, embedded: true

      link :team do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/teams/#{represented.team.id}" if represented.team
      end

      link :created_by do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/users/#{represented.created_by.id}" if represented.created_by
      end

      link :self do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/seasons/#{current_id}"
      end

      def current_id
        represented.persisted? ? represented.id : 'current'
      end
    end
  end
end
