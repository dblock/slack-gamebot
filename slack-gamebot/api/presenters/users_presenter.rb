module Api
  module Presenters
    module UsersPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer
      include Api::Presenters::PaginatedPresenter

      collection :results, extend: UserPresenter, as: :users, embedded: true
    end
  end
end
