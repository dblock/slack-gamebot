module Api
  module Endpoints
    class TeamsEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters

      namespace :teams do
        desc 'Get a team.'
        params do
          requires :id, type: String, desc: 'Team ID.'
        end
        get ':id' do
          team = Team.find(params[:id]) || error!(404, 'Not Found')
          present team, with: Api::Presenters::TeamPresenter
        end

        desc 'Get all the teams.'
        params do
          use :pagination
        end
        sort Team::SORT_ORDERS
        get do
          teams = paginate_and_sort_by_cursor(Team, default_sort_order: '-_id')
          present teams, with: Api::Presenters::TeamsPresenter
        end

        desc 'Create a team using an OAuth token.'
        params do
          requires :code, type: String
        end
        post do
          fail 'Missing SLACK_CLIENT_ID and/or SLACK_CLIENT_SECRET.' unless ENV['SLACK_CLIENT_ID'] && ENV['SLACK_CLIENT_SECRET']

          client = Slack::Web::Client.new

          rc = client.oauth_access(
            client_id: ENV['SLACK_CLIENT_ID'],
            client_secret: ENV['SLACK_CLIENT_SECRET'],
            code: params[:code]
          )

          team = Team.create!(
            token: rc['bot']['bot_access_token'],
            team_id: rc['team_id'],
            name: rc['team_name'],
            secret: SecureRandom.hex(16)
          )

          SlackGamebot::Service.start!(team)
          present team, with: Api::Presenters::TeamPresenter
        end
      end
    end
  end
end
