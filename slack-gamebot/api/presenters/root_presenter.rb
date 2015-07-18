module Api
  module Presenters
    module RootPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      link :self do |opts|
        "#{base_url(opts)}/"
      end

      link :users do |opts|
        {
          href: "#{base_url(opts)}/users/#{PAGINATION_PARAMS}",
          templated: true
        }
      end

      link :challenges do |opts|
        {
          href: "#{base_url(opts)}/challenges/#{PAGINATION_PARAMS}",
          templated: true
        }
      end

      link :matches do |opts|
        {
          href: "#{base_url(opts)}/matches/#{PAGINATION_PARAMS}",
          templated: true
        }
      end

      link :current_season do |opts|
        "#{base_url(opts)}/seasons/current"
      end

      link :seasons do |opts|
        {
          href: "#{base_url(opts)}/seasons/#{PAGINATION_PARAMS}",
          templated: true
        }
      end

      [:challenge, :match, :user, :season].each do |model|
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

      PAGINATION_PARAMS = "{?#{Api::Helpers::PaginationParameters::ALL.join(',')}}"
    end
  end
end
