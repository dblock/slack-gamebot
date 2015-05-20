module Api
  class UsersEndpoint < Grape::API
    format :json

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
        optional :page, type: Integer, default: 1, desc: 'Page of users to return.'
        optional :size, type: Integer, default: 3, desc: 'Number of users to return.'
      end
      get do
        present Kaminari.paginate_array(User.all).page(params[:page]).per(params[:size]), with: Api::Presenters::UsersPresenter
      end
    end
  end
end
