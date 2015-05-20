module Api
  module Presenters
    module UsersPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer
      include Api::Presenters::PaginatedPresenter

      collection :to_a, extend: UserPresenter, as: :users, embedded: true
    end
  end
end
