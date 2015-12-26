module Api
  module Presenters
    module RootPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      link :self do |opts|
        "#{base_url(opts)}/"
      end

      link :status do |opts|
        "#{base_url(opts)}/status"
      end

      link :users do |opts|
        {
          href: "#{base_url(opts)}/users/#{params(Api::Helpers::PaginationParameters::ALL, :team_id, :captain)}",
          templated: true
        }
      end

      link :challenges do |opts|
        {
          href: "#{base_url(opts)}/challenges/#{params(Api::Helpers::PaginationParameters::ALL, :team_id)}",
          templated: true
        }
      end

      link :matches do |opts|
        {
          href: "#{base_url(opts)}/matches/#{params(Api::Helpers::PaginationParameters::ALL, :team_id)}",
          templated: true
        }
      end

      link :current_season do |opts|
        {
          href: "#{base_url(opts)}/seasons/current/{?team_id}",
          templated: true
        }
      end

      link :seasons do |opts|
        {
          href: "#{base_url(opts)}/seasons/#{params(Api::Helpers::PaginationParameters::ALL, :team_id)}",
          templated: true
        }
      end

      link :teams do |opts|
        {
          href: "#{base_url(opts)}/teams/#{params(Api::Helpers::PaginationParameters::ALL, :active, :game_id)}",
          templated: true
        }
      end

      link :games do |opts|
        {
          href: "#{base_url(opts)}/games/#{params(Api::Helpers::PaginationParameters::ALL)}",
          templated: true
        }
      end

      [:challenge, :match, :user, :season, :team, :game].each do |model|
        link model do |opts|
          {
            href: "#{base_url(opts)}/#{model.to_s.pluralize}/{id}",
            templated: true
          }
        end
      end

      private

      def base_url(opts)
        request = Grape::Request.new(opts[:env])
        request.base_url
      end

      def params(*args)
        "{?#{args.join(',')}}"
      end
    end
  end
end
