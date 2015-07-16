module Api
  module Presenters
    module SeasonPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      property :id, type: String, desc: 'Season ID.'
      property :created_at, type: DateTime, desc: 'Date/time when the season was created.'

      collection :user_ranks, extend: UserRankPresenter, embedded: true

      link :created_by do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/users/#{represented.created_by.id}" if represented.created_by
      end

      link :self do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/seasons/#{id}"
      end
    end
  end
end
