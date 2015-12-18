module Api
  module Endpoints
    class ChallengesEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters

      namespace :challenges do
        desc 'Get a challenge.'
        params do
          requires :id, type: String, desc: 'Challenge ID.'
        end
        get ':id' do
          challenge = Challenge.find(params[:id]) || error!(404, 'Not Found')
          present challenge, with: Api::Presenters::ChallengePresenter
        end

        desc 'Get all the challenges.'
        params do
          requires :team_id, type: String
          use :pagination
        end
        sort Challenge::SORT_ORDERS
        get do
          query = Challenge.where(team_id: params[:team_id])
          challenges = paginate_and_sort_by_cursor(query, default_sort_order: '-_id')
          present challenges, with: Api::Presenters::ChallengesPresenter
        end
      end
    end
  end
end
