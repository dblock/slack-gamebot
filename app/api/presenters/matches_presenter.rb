module Api
  module Presenters
    module MatchesPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer
      include Api::Presenters::PaginatedPresenter

      collection :to_a, extend: MatchPresenter, as: :matches, embedded: true
    end
  end
end
