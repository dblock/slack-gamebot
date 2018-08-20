module SlackRubyBot
  module Hooks
    class Hello
      def call(client, _data)
        return unless client && client.team
        socket = client.instance_variable_get(:@socket)
        driver = socket.instance_variable_get(:@driver)
        logger.info [driver.object_id, "Successfully connected team #{client.team.name} (#{client.team.id}) to https://#{client.team.domain}.slack.com."]
      end
    end
  end
end
