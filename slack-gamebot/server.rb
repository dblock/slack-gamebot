module SlackGamebot
  class Server < SlackRubyBot::Server
    include SlackGamebot::Hooks::UserChange
  end
end
