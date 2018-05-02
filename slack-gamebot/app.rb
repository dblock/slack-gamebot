module SlackGamebot
  class App < SlackRubyBotServer::App
    include Celluloid

    DEAD_MESSAGE = <<-EOS.freeze
This leaderboard has been dead for over a month, deactivating.
Re-install the bot at https://www.playplay.io. Your data will be purged in 2 weeks.
EOS

    def prepare!
      update_subscribed_at!
      super
      deactivate_dead_teams!
    end

    def after_start!
      inform_dead_teams!
      once_and_every 60 * 60 * 24 do
        check_trials!
      end
      once_and_every 60 * 60 * 24 * 3 do
        check_subscribed_teams!
      end
    end

    private

    def once_and_every(tt)
      yield
      every tt do
        yield
      end
    end

    def update_subscribed_at!
      Team.subscribed.each do |team|
        next if team.subscribed_at
        if team.stripe_customer_id
          customer = Stripe::Customer.retrieve(client.owner.stripe_customer_id)
          team.update_attributes!(subscribed_at: customer.created)
        else
          team.update_attributes!(subscribed_at: team.updated_at)
        end
        logger.info("Team #{team} subscribed since #{team.subscribed_at}.")
      end
    end

    def inform_dead_teams!
      Team.where(active: false).each do |team|
        next if team.dead_at
        begin
          team.dead! DEAD_MESSAGE, 'dead'
        rescue StandardError => e
          logger.warn "Error informing dead team #{team}, #{e.message}."
        end
      end
    end

    def deactivate_dead_teams!
      Team.active.each do |team|
        next if team.subscribed?
        next unless team.dead?
        begin
          team.deactivate!
        rescue StandardError => e
          logger.warn "Error deactivating team #{team}, #{e.message}."
        end
      end
    end

    def check_trials!
      Team.where(subscribed: false).each do |team|
        begin
          logger.info "Team #{team} has #{team.remaining_trial_days} trial days left."
          next unless team.remaining_trial_days <= 3
          team.inform_trial!
        rescue StandardError => e
          logger.warn "Error checking team #{team} trial, #{e.message}."
        end
      end
    end

    def check_subscribed_teams!
      Team.where(subscribed: true, :stripe_customer_id.ne => nil).each do |team|
        customer = Stripe::Customer.retrieve(team.stripe_customer_id)
        customer.subscriptions.each do |subscription|
          subscription_name = "#{subscription.plan.name} (#{ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)})"
          logger.info "Checking #{team} subscription to #{subscription_name}, #{subscription.status}."
          case subscription.status
          when 'past_due'
            logger.warn "Subscription for #{team} is #{subscription.status}, notifying."
            team.inform_admin! "Your subscription to #{subscription_name} is past due. #{team.update_cc_text}"
          when 'canceled', 'unpaid'
            logger.warn "Subscription for #{team} is #{subscription.status}, downgrading."
            team.inform_admin! "Your subscription to #{subscription.plan.name} (#{ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)}) was canceled and your team has been downgraded. Thank you for being a customer!"
            team.update_attributes!(subscribed: false)
          end
        end
      end
    end
  end
end
