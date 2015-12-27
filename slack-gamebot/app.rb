module SlackGamebot
  class App
    def prepare!
      silence_loggers!
      check_mongodb_provider!
      check_database!
      migrate_from_single_team!
      mark_teams_as_active!
      ensure_a_team_captain!
      migrate_from_single_game!
      ensure_a_team_game!
    end

    def self.instance
      @instance ||= SlackGamebot::App.new
    end

    private

    def logger
      @logger ||= begin
        $stdout.sync = true
        Logger.new(STDOUT)
      end
    end

    def silence_loggers!
      Mongoid.logger.level = Logger::INFO
      Mongo::Logger.logger.level = Logger::INFO
    end

    def check_mongodb_provider!
      return unless ENV['RACK_ENV'] == 'production'
      fail "Missing ENV['MONGOHQ_URI'] or ENV['MONGOLAB_URI']." unless ENV['MONGOHQ_URI'] || ENV['MONGOLAB_URI']
    end

    def check_database!
      rc = Mongoid.default_client.command(ping: 1)
      return if rc && rc.ok?
      fail rc.documents.first['error'] || 'Unexpected error.'
    rescue Exception => e
      warn "Error connecting to MongoDB: #{e.message}"
      raise e
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
  end
end
