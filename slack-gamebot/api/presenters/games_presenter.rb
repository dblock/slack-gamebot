module Api
  module Presenters
    module GamesPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer
      include Api::Presenters::PaginatedPresenter

      collection :results, extend: GamePresenter, as: :games, embedded: true
    end
  end
end
