# frozen_string_literal: true

module SlackRubyBot
  class Client < Slack::RealTime::Client
    attr_accessor :send_gifs, :aliases

    def initialize(attrs = {})
      super
      @send_gifs = attrs[:send_gifs]
      @aliases = attrs[:aliases]
    end

    def send_gifs?
      send_gifs.nil? || send_gifs
    end

    def say(options = {})
      options = options.dup
      # get GIF
      keywords = options.delete(:gif)
      # text
      text = options.delete(:text)
      gif = Giphy.random(keywords) if keywords && send_gifs?
      text = [text, gif].compact.join("\n")
      message({ text: }.merge(options))
    end
  end
end
