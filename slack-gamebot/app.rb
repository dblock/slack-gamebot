module SlackGamebot
  class App < SlackRubyBotServer::App
    DEAD_MESSAGE = <<-EOS.freeze
This leaderboard has been dead for over a month, deactivating.
Re-install the bot at https://www.playplay.io. Your data will be purged in 2 weeks.
EOS

    def prepare!
      super
      deactivate_dead_teams!
    end

    def after_start!
      check_premium_teams!
      nudge_sleeping_teams!
      bother_free_teams!
    end

    private

    def deactivate_dead_teams!
      Team.active.each do |team|
        next if team.premium?
        next unless team.dead?
        begin
          team.deactivate!
          team.inform! DEAD_MESSAGE, 'dead'
        rescue StandardError => e
          logger.warn "Error informing team #{team}, #{e.message}."
        end
      end
    end

    def nudge_sleeping_teams!
      Team.active.each do |team|
        next unless team.nudge?
        begin
          team.nudge!
        rescue StandardError => e
          logger.warn "Error nudging team #{team}, #{e.message}."
        end
      end
    end

    def bother_free_teams!
      Team.active.each do |team|
        next if team.premium?
        next unless team.bother?
        begin
          team.bother! "Enjoying this free bot? Don't be cheap! #{team.upgrade_text}"
        rescue StandardError => e
          logger.warn "Error bothering team #{team}, #{e.message}."
        end
      end
    end

    def check_premium_teams!
      Team.where(premium: true, :stripe_customer_id.ne => nil).each do |team|
        customer = Stripe::Customer.retrieve(team.stripe_customer_id)
        customer.subscriptions.each do |subscription|
          subscription_name = "#{subscription.plan.name} (#{ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)})"
          logger.info "Checking #{team} subscription to #{subscription_name}, #{subscription.status}."
          case subscription.status
          when 'past_due'
            logger.warn "Subscription for #{team} is #{subscription.status}, notifying."
            team.inform! "Your premium subscription to #{subscription_name} is past due. #{team.update_cc_text}"
          when 'canceled', 'unpaid'
            logger.warn "Subscription for #{team} is #{subscription.status}, downgrading."
            team.inform! "Your premium subscription to #{subscription.plan.name} (#{ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)}) was canceled and your team has been downgraded. Thank you for being a customer!"
            team.update_attributes!(premium: false)
          end
        end
      end
    end
  end
end
