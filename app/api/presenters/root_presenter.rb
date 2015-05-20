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
          href: "#{base_url(opts)}/users{?page,size}",
          templated: true
        }
      end

      link :user do |opts|
        {
          href: "#{base_url(opts)}/users/{id}",
          templated: true
        }
      end

      private

      def base_url(opts)
        request = Grape::Request.new(opts[:env])
        request.base_url
      end
    end
  end
end
