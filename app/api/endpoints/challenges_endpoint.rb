module Api
  module Endpoints
    class ChallengesEndpoint < Grape::API
      format :json

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
          optional :page, type: Integer, default: 1, desc: 'Page of challenges to return.'
          optional :size, type: Integer, default: 3, desc: 'Number of challenges to return.'
        end
        get do
          present Kaminari.paginate_array(Challenge.all).page(params[:page]).per(params[:size]), with: Api::Presenters::ChallengesPresenter
        end
      end
    end
  end
end
