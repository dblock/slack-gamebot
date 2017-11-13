module Api
  module Presenters
    module GamePresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      property :id, type: String, desc: 'Game ID.'
      property :name, type: String, desc: 'Name of the game.'
      property :bot_name, type: String, desc: 'Bot name.'
      property :aliases, type: Array, desc: 'Game aliases.'
      property :client_id, type: String, desc: 'Slack client ID.'
      property :created_at, type: DateTime, desc: 'Date/time when the game was created.'
      property :updated_at, type: DateTime, desc: 'Date/time when the game was accepted, declined or canceled.'

      link :teams do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/teams?game_id=#{represented.id}"
      end

      link :self do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/games/#{id}"
      end
    end
  end
end
