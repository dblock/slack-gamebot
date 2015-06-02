module Api
  module Presenters
    module ChallengesPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer
      include Api::Presenters::PaginatedPresenter

      collection :results, extend: ChallengePresenter, as: :challenges, embedded: true
    end
  end
end
