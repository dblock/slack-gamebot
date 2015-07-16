module Api
  module Endpoints
    class SeasonsEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters

      namespace :seasons do
        desc 'Get current season.'
        get 'current' do
          present Season.new, with: Api::Presenters::SeasonPresenter
        end

        desc 'Get a season.'
        params do
          requires :id, type: String, desc: 'Season ID.'
        end
        get ':id' do
          season = Season.find(params[:id]) || error!(404, 'Not Found')
          present season, with: Api::Presenters::SeasonPresenter
        end

        desc 'Get all past seasons.'
        params do
          use :pagination
        end
        sort Season::SORT_ORDERS
        get do
          seasons = paginate_and_sort_by_cursor(Season, default_sort_order: '-_id')
          present seasons, with: Api::Presenters::SeasonsPresenter
        end
      end
    end
  end
end
