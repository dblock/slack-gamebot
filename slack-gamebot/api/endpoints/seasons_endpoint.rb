module Api
  module Endpoints
    class SeasonsEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters

      namespace :seasons do
        desc 'Get current season.'
        params do
          requires :team_id, type: String
        end
        get 'current' do
          team = Team.find(params[:team_id]) || error!('Not Found', 404)
          present Season.new(team: team), with: Api::Presenters::SeasonPresenter
        end

        desc 'Get a season.'
        params do
          requires :id, type: String, desc: 'Season ID.'
        end
        get ':id' do
          season = Season.find(params[:id]) || error!('Not Found', 404)
          present season, with: Api::Presenters::SeasonPresenter
        end

        desc 'Get all past seasons.'
        params do
          requires :team_id, type: String
          use :pagination
        end
        sort Season::SORT_ORDERS
        get do
          query = Season.where(team_id: params[:team_id])
          seasons = paginate_and_sort_by_cursor(query, default_sort_order: '-_id')
          present seasons, with: Api::Presenters::SeasonsPresenter
        end
      end
    end
  end
end
