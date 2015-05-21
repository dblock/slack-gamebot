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
          href: "#{base_url(opts)}/users/{?page,size}",
          templated: true
        }
      end

      link :challenges do |opts|
        {
          href: "#{base_url(opts)}/challenges/{?page,size}",
          templated: true
        }
      end

      link :matches do |opts|
        {
          href: "#{base_url(opts)}/matches/{?page,size}",
          templated: true
        }
      end

      [:challenge, :match, :user].each do |model|
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
    end
  end
end
