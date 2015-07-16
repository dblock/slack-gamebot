module Api
  module Presenters
    module UserRankPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      property :id, type: String, desc: 'UserRank ID.'
      property :user_name, type: String, desc: 'UserRank name.'
      property :wins, type: Integer, desc: 'Number of wins.'
      property :losses, type: Integer, desc: 'Number of losses.'
      property :elo, type: Integer, desc: 'Elo.'
      property :rank, type: Integer, desc: 'Rank.'

      link :user do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/users/#{user_id}"
      end
    end
  end
end
