require 'slack/real_time/concurrency/celluloid'
require 'celluloid/internals/logger'

Slack::RealTime::Client.configure do |config|
  config.websocket_ping = 5
end

module Slack
  module RealTime
    module Concurrency
      module Celluloid
        class Socket < Slack::RealTime::Socket
          include ::Celluloid::Internals::Logger

          def initialize(*args)
            super
            logger.level = Logger::INFO
          end

          def log_info(message)
            if message == @message
              @count += 1
            else
              if @message && @message.is_a?(Array) && @count && @count > 1
                logger.info(@message.concat(["repeated #{@count} times"]))
              end
              @count = 1
              @message = message
              logger.info(message)
            end
          end

          def read
            buffer = socket.readpartial(BLOCK_SIZE)
            log_info([driver.object_id, "got a nil buffer"]) unless buffer
            log_info([driver.object_id, "got an empty buffer"]) if buffer && buffer.size == 0
            if buffer
              # log_info [driver.object_id, buffer.to_hex_string]
              async.handle_read(buffer)
            end
          end

          def build_driver
            @logger = Logger.new(STDOUT)
            @logger.level = Logger::INFO
            ::WebSocket::Driver.client(self).tap do |ws|
              ws.on :open do
                log_info [ws.object_id, :server_open]
              end

              ws.on :message do |message|
                log_info [ws.object_id, :server_message]
              end

              ws.on :close do |close|
                log_info [ws.object_id, :server_close, close.code, close.reason]
              end

              ws.on :error do |error|
                log_info [ws.object_id, :server_error, error.message]
              end

              ws.on :ping do |ping|
                log_info [ws.object_id, :server_ping]
              end

              ws.on :pong do |pong|
                log_info [ws.object_id, :server_pong]
              end
            end
          end
        end
      end
    end
  end
end


