module Api
  module Presenters
    module StatusPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      link :self do |opts|
        "#{base_url(opts)}/status"
      end

      property :teams_count
      property :active_teams_count
      property :users_count
      property :challenges_count
      property :matches_count
      property :seasons_count
      property :ping

      private

      def teams_count
        Team.count
      end

      def users_count
        User.count
      end

      def challenges_count
        Challenge.count
      end

      def matches_count
        Match.count
      end

      def seasons_count
        Season.count
      end

      def active_teams_count
        Team.active.count
      end

      def ping
        team = Team.asc(:_id).first
        team.ping! if team
      end

      def base_url(opts)
        request = Grape::Request.new(opts[:env])
        request.base_url
      end
    end
  end
end
