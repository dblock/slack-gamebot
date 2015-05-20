module Api
  class RootEndpoint < Grape::API
    format :json
    formatter :json, Grape::Formatter::Roar
    get do
      present self, with: Api::Presenters::RootPresenter
    end
    mount Api::UsersEndpoint
  end
end
