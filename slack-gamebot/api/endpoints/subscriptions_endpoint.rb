module Api
  module Endpoints
    class SubscriptionsEndpoint < Grape::API
      format :json

      namespace :subscriptions do
        desc 'Subscribe to slack-playplay.'
        params do
          requires :stripe_token, type: String
          requires :stripe_token_type, type: String
          requires :stripe_email, type: String
          optional :stripe_coupon, type: String
          requires :team_id, type: String
        end
        post do
          team = Team.find(params[:team_id]) || error!('Not Found', 404)
          Api::Middleware.logger.info "Creating a subscription for team #{team}, email=#{params[:stripe_email]}, coupon=#{params[:stripe_coupon]}."
          error!('Already a Subscriber', 400) if team.subscribed?
          error!('Existing Subscription Already Active', 400) if team.stripe_customer_id && team.stripe_customer.subscriptions.any?
          data = {
            source: params[:stripe_token],
            plan: 'slack-playplay-yearly',
            email: params[:stripe_email],
            coupon: params[:stripe_coupon],
            metadata: {
              id: team._id.to_s,
              team_id: team.team_id,
              name: team.name,
              domain: team.domain,
              game: team.game.name
            }
          }
          customer = team.stripe_customer_id ? Stripe::Customer.update(team.stripe_customer_id, data) : Stripe::Customer.create(data)
          Api::Middleware.logger.info "Subscription for team #{team} created, stripe_customer_id=#{customer['id']}."
          team.update_attributes!(subscribed: true, stripe_customer_id: customer['id'])
          present team, with: Api::Presenters::TeamPresenter
        end
      end
    end
  end
end
