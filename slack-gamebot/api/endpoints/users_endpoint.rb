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
          use :pagination
        end
        sort User::SORT_ORDERS
        get do
          users = paginate_and_sort_by_cursor(User, default_sort_order: '-elo')
          present users, with: Api::Presenters::UsersPresenter
        end
      end
    end
  end
end
