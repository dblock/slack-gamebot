module Api
  module Endpoints
    class RootEndpoint < Grape::API
      include Api::Helpers::ErrorHelpers

      prefix :api
      format :json
      formatter :json, Grape::Formatter::Roar
      get do
        present self, with: Api::Presenters::RootPresenter
      end

      mount Api::Endpoints::StatusEndpoint
      mount Api::Endpoints::UsersEndpoint
      mount Api::Endpoints::ChallengesEndpoint
      mount Api::Endpoints::MatchesEndpoint
      mount Api::Endpoints::SeasonsEndpoint
      mount Api::Endpoints::TeamsEndpoint
      mount Api::Endpoints::GamesEndpoint
      mount Api::Endpoints::SubscriptionsEndpoint

      add_swagger_documentation
    end
  end
end
