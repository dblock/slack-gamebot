module Api
  module Presenters
    module UserRanksPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer
      include Api::Presenters::PaginatedPresenter

      collection :results, extend: UserRankPresenter, as: :user_ranks, embedded: true
    end
  end
end
