module SlackRubyBot
  class Ping
    include Celluloid

    def initialize(client)
      @client = client
    end

    attr_reader :client

    def socket
      @client.instance_variable_get(:@socket)
    end

    def driver
      socket&.instance_variable_get(:@driver)
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def team
      return unless client
      # THIS IS WRONG! Needs game
      Team.where(team_id: client.team.id).first
    end

    def ping!
      logger.level = Logger::INFO
      every 3 * 60 do
        next unless driver
        t = team
        next unless t
        ping = t.ping!
        next if ping[:presence].online
        logger.info [driver.object_id, :ping, 'down']
        after 30 do
          logger.info [driver.object_id, :reping]
          ping = t.ping!
          if ping[:presence].online
            logger.info [driver.object_id, :reping, 'back']
          else
            logger.info [driver.object_id, :reping, 'down']
            driver.emit(:close, WebSocket::Driver::CloseEvent.new(1001, 'server mia'))
          end
        end
      end
    rescue StandardError => e
      logger.warn e
    end
  end

  class Client
    def ping!
      Ping.new(self).ping!
    end
  end
end
