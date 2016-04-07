module SlackGamebot
  class App
    include SlackRubyBot::Loggable

    def prepare!
      silence_loggers!
      check_mongodb_provider!
      check_database!
      create_indexes!
      migrate_from_single_team!
      mark_teams_as_active!
      ensure_a_team_captain!
      migrate_from_single_game!
      ensure_a_team_game!
      deactivate_dead_teams!
      purge_inactive_teams!
      nudge_sleeping_teams!
      set_team_gifs_default!
      set_team_aliases!
      set_team_api_default!
    end

    def self.instance
      @instance ||= SlackGamebot::App.new
    end

    private

    def silence_loggers!
      Mongoid.logger.level = Logger::INFO
      Mongo::Logger.logger.level = Logger::INFO
    end

    def check_mongodb_provider!
      return unless ENV['RACK_ENV'] == 'production'
      fail "Missing ENV['MONGO_URL'], ENV['MONGOHQ_URI'] or ENV['MONGOLAB_URI']." unless ENV['MONGO_URL'] || ENV['MONGOHQ_URI'] || ENV['MONGOLAB_URI']
    end

    def check_database!
      rc = Mongoid.default_client.command(ping: 1)
      return if rc && rc.ok?
      fail rc.documents.first['error'] || 'Unexpected error.'
    rescue Exception => e
      warn "Error connecting to MongoDB: #{e.message}"
      raise e
    end

    def create_indexes!
      ::Mongoid::Tasks::Database.create_indexes
    end

    def migrate_from_single_team!
      return unless ENV.key?('SLACK_API_TOKEN')
      logger.info 'Migrating from env SLACK_API_TOKEN ...'
      team = Team.find_or_create_from_env!
      logger.info "Automatically migrated team: #{team}."
      User.where(team: nil).update_all(team_id: team.id)
      Challenge.where(team: nil).update_all(team_id: team.id)
      Season.where(team: nil).update_all(team_id: team.id)
      Match.where(team: nil).update_all(team_id: team.id)
      logger.warn "You should unset ENV['SLACK_API_TOKEN'] and ENV['GAMEBOT_SECRET']."
    end

    def migrate_from_single_game!
      return unless ENV.key?('SLACK_CLIENT_ID') && ENV.key?('SLACK_CLIENT_SECRET')
      logger.info 'Migrating from env SLACK_CLIENT_ID and SLACK_CLIENT_SECRET ...'
      game = Game.find_or_create_from_env!
      logger.info "Automatically migrated game: #{game}."
      Team.where(game: nil).update_all(game_id: game.id)
      logger.warn "You should unset ENV['SLACK_CLIENT_ID'], ENV['SLACK_CLIENT_SECRET'] and ENV['SLACK_RUBY_BOT_ALIASES']."
    end

    def mark_teams_as_active!
      Team.where(active: nil).update_all(active: true)
    end

    def ensure_a_team_captain!
      Team.each do |team|
        next if team.captains.count > 0
        team.unset :secret
        user = team.users.asc(:_id).first
        next unless user
        user.promote!
        logger.info "#{team}: promoted #{user} to captain."
      end
    end

    def ensure_a_team_game!
      game = Game.first || Game.create!(name: 'default')
      Team.where(game: nil).update_all(game_id: game.id)
    end

    def deactivate_dead_teams!
      Team.active.each do |team|
        next unless team.dead?
        begin
          team.deactivate!
          team.inform! 'This leaderboard has been dead for over a month, deactivating. Your data will be purged in 2 weeks.', 'dead'
        rescue StandardError => e
          logger.warn "Error informing team #{team}, #{e.message}."
        end
      end
    end

    def purge_inactive_teams!
      Team.purge!
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

    # default team GIFs to true
    def set_team_gifs_default!
      Team.where(gifs: nil).update_all(gifs: true)
    end

    # game aliases get copied onto teams upon creation and can be modified by team captains
    def set_team_aliases!
      Game.each do |game|
        game.teams.where(aliases: nil).update_all(aliases: game.aliases)
      end
    end

    # default team API to false
    def set_team_api_default!
      Team.where(api: nil).update_all(api: false)
    end
  end
end
