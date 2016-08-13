module SlackGamebot
  class App < SlackRubyBotServer::App
    DEAD_MESSAGE = <<-EOS
This leaderboard has been dead for over a month, deactivating.
Re-install the bot at https://www.playplay.io. Your data will be purged in 2 weeks.
EOS

    def prepare!
      super
      update_unbalanced_teams!
      deactivate_dead_teams!
      nudge_sleeping_teams!
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

    def update_unbalanced_teams!
      Team.where(unbalanced: nil).update_all(unbalanced: false)
    end
  end
end
