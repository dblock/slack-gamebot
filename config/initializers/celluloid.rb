require 'slack/real_time/concurrency/celluloid'
require 'celluloid/internals/logger'

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

          def read
            buffer = socket.readpartial(BLOCK_SIZE)
            raise EOFError unless buffer && !buffer.empty?
            async.handle_read(buffer)
          end

          def build_driver
            @logger = Logger.new(STDOUT)
            @logger.level = Logger::INFO

            ::WebSocket::Driver.client(self).tap do |ws|
              ws.on :open do
                logger.info [ws.object_id, :server_open]
              end

              ws.on :close do |close|
                logger.info [ws.object_id, :server_close, close.code, close.reason]
              end

              ws.on :error do |error|
                logger.info [ws.object_id, :server_error, error.message]
              end
            end
          end
        end
      end
    end
  end
end


