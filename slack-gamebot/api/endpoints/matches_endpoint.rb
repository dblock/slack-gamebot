module Api
  module Endpoints
    class MatchesEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters

      namespace :matches do
        desc 'Get a match.'
        params do
          requires :id, type: String, desc: 'Match ID.'
        end
        get ':id' do
          match = Match.find(params[:id]) || error!('Not Found', 404)
          error!('Not Found', 404) unless match.team.api?
          present match, with: Api::Presenters::MatchPresenter
        end

        desc 'Get all the matches.'
        params do
          requires :team_id, type: String
          use :pagination
        end
        sort Match::SORT_ORDERS
        get do
          team = Team.find(params[:team_id]) || error!('Not Found', 404)
          error!('Not Found', 404) unless team.api?
          matches = paginate_and_sort_by_cursor(team.matches, default_sort_order: '-_id')
          present matches, with: Api::Presenters::MatchesPresenter
        end
      end
    end
  end
end
