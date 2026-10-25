SlackRubyBotServer.configure do |config|
  config.server_pages do |pages|
    pages.cache_control = 'private, no-cache'
  end
end
