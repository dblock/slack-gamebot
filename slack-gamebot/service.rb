module SlackGamebot
  class Service
    LOCK = Mutex.new
    @services = {}

    class << self
      def start!(team)
        fail 'Token already known.' if @services.key?(team.token)
        EM.next_tick do
          server = SlackGamebot::Server.new(team: team)
          LOCK.synchronize do
            @services[team.token] = server
          end
          restart!(server)
        end
      rescue StandardError => e
        logger.error e
      end

      def stop!(team)
        LOCK.synchronize do
          fail 'Token unknown.' unless @services.key?(team.token)
          EM.next_tick do
            @services[team.token].stop!
            @services.delete(team.token)
          end
        end
      rescue StandardError => e
        logger.error e
      end

      def logger
        @logger ||= begin
          $stdout.sync = true
          Logger.new(STDOUT)
        end
      end

      def start_from_database!
        Team.each do |team|
          start!(team)
        end
      end

      def restart!(server, wait = 1)
        server.auth!
        server.start_async
      rescue StandardError => e
        logger.error "#{server.token[0..10]}***: #{e.message}, restarting in #{wait} second(s)."
        sleep(wait)
        EM.next_tick do
          restart! server, [wait * 2, 60].min
        end
      end
    end
  end
end
