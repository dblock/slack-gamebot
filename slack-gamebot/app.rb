module SlackGamebot
  class App < SlackRubyBotServer::App
    DEAD_MESSAGE = <<~EOS.freeze
      This leaderboard has been dead for over a month, deactivating.
      Re-install the bot at https://www.playplay.io. Your data will be purged in 2 weeks.
    EOS

    def after_start!
      once_and_every 60 * 60 * 24 do
        check_trials!
        deactivate_dead_teams!
        inform_dead_teams!
        check_subscribed_teams!
        check_active_subscriptions_without_teams!
      end
    end

    private

    def once_and_every(tt)
      ::Async::Reactor.run do |task|
        loop do
          yield
          task.sleep tt
        end
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
      Team.active.where(subscribed: false).each do |team|
        logger.info "Team #{team} has #{team.remaining_trial_days} trial days left."
        next unless team.remaining_trial_days > 0 && team.remaining_trial_days <= 3

        team.inform_trial!
      rescue StandardError => e
        logger.warn "Error checking team #{team} trial, #{e.message}."
      end
    end

    def check_subscribed_teams!
      Team.where(subscribed: true, :stripe_customer_id.ne => nil).each do |team|
        if team.subscribed? && team.stripe_customer.subscriptions.none?
          logger.info "No active subscriptions for #{team} (#{team.stripe_customer_id}), downgrading."
          team.inform_admin! 'Your subscription was canceled and your team has been downgraded. Thank you for being a customer!'
          team.update_attributes!(subscribed: false)
        else
          team.stripe_customer.subscriptions.each do |subscription|
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
      rescue StandardError => e
        logger.warn "Error checking team #{team} subscription, #{e.message}."
      end
    end

    def check_active_subscriptions_without_teams!
      Stripe::Subscription.all(plan: 'slack-playplay-yearly').each do |subscription|
        next if subscription.cancel_at_period_end
        next if Team.where(stripe_customer_id: subscription.customer).exists?

        customer = Stripe::Customer.retrieve(subscription.customer)
        logger.warn "Customer #{customer.email}, team #{customer.metadata['name']} is #{subscription.status}, but customer no longer exists."
      end
    end
  end
end
