module Api
  module Endpoints
    class UsersEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters

      namespace :users do
        desc 'Get a user.'
        params do
          requires :id, type: String, desc: 'User ID.'
        end
        get ':id' do
          user = User.find(params[:id]) || error!(404, 'Not Found')
          present user, with: Api::Presenters::UserPresenter
        end

        desc 'Get all the users.'
        params do
          requires :team_id, type: String
          optional :is_admin, type: Boolean
          use :pagination
        end
        sort User::SORT_ORDERS
        get do
          query = User.where(team_id: params[:team_id])
          query = query.admins if params[:is_admin]
          users = paginate_and_sort_by_cursor(query, default_sort_order: '-elo')
          present users, with: Api::Presenters::UsersPresenter
        end
      end
    end
  end
end
