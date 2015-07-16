module Api
  module Presenters
    module SeasonsPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer
      include Api::Presenters::PaginatedPresenter

      collection :results, extend: SeasonPresenter, as: :seasons, embedded: true
    end
  end
end
