module Api
  module Presenters
    module StatusPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      link :self do |opts|
        "#{base_url(opts)}/status"
      end

      property :games_count
      property :games

      def games_count
        Game.count
      end

      def games
        Game.all.each_with_object({}) do |game, h|
          h[game.name] = {}
          h[game.name][:teams_count] = game.teams.count
          h[game.name][:active_teams_count] = game.teams.active.count
          h[game.name][:api_teams_count] = game.teams.api.count
          h[game.name][:users_count] = game.users.count
          h[game.name][:challenges_count] = game.challenges.count
          h[game.name][:matches_count] = game.matches.count
          h[game.name][:seasons_count] = game.seasons.count
          team = game.teams.active.asc(:_id).first
          h[game.name][:ping] = team.ping_if_active! if team
        end
      end

      private

      def base_url(opts)
        request = Grape::Request.new(opts[:env])
        request.base_url
      end
    end
  end
end
