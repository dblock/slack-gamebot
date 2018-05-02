module Api
  module Endpoints
    class CreditCardsEndpoint < Grape::API
      format :json

      namespace :credit_cards do
        desc 'Updates a credit card.'
        params do
          requires :stripe_token, type: String
          optional :stripe_token_type, type: String
          optional :stripe_email, type: String
          requires :team_id, type: String
        end
        post do
          team = Team.find(params[:team_id]) || error!('Not Found', 404)
          error!('Not a Subscriber', 400) unless team.stripe_customer_id
          customer = Stripe::Customer.retrieve(team.stripe_customer_id)
          customer.source = params['stripe_token']
          customer.save
          Api::Middleware.logger.info "Updated credit card for team #{team}, email=#{params[:stripe_email]}."
          present team, with: Api::Presenters::TeamPresenter
        end
      end
    end
  end
end
