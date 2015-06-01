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
      property :created_at, as: :registered_at, type: DateTime, desc: 'Date/time when the user has registered.'

      link :self do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/users/#{id}"
      end
    end
  end
end
