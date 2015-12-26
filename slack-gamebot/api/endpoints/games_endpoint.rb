module Api
  module Endpoints
    class GamesEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters

      namespace :games do
        desc 'Get a game.'
        params do
          requires :id, type: String, desc: 'Game ID.'
        end
        get ':id' do
          game = Game.find(params[:id]) || error!('Not Found', 404)
          present game, with: Api::Presenters::GamePresenter
        end

        desc 'Get all the games.'
        params do
          optional :active, type: Boolean, desc: 'Return active games only.'
          use :pagination
        end
        sort Game::SORT_ORDERS
        get do
          games = paginate_and_sort_by_cursor(Game.all, default_sort_order: '-_id')
          present games, with: Api::Presenters::GamesPresenter
        end
      end
    end
  end
end
