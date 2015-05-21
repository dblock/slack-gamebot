module Api
  module Endpoints
    class MatchesEndpoint < Grape::API
      format :json

      namespace :matches do
        desc 'Get a match.'
        params do
          requires :id, type: String, desc: 'Match ID.'
        end
        get ':id' do
          match = Match.find(params[:id]) || error!(404, 'Not Found')
          present match, with: Api::Presenters::MatchPresenter
        end

        desc 'Get all the matches.'
        params do
          optional :page, type: Integer, default: 1, desc: 'Page of matches to return.'
          optional :size, type: Integer, default: 3, desc: 'Number of matches to return.'
        end
        get do
          present Kaminari.paginate_array(Match.all).page(params[:page]).per(params[:size]), with: Api::Presenters::MatchesPresenter
        end
      end
    end
  end
end
