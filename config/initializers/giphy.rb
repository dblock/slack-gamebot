module Giphy
  def self.random(keywords)
    return unless ENV.key?('GIPHY_API_KEY')

    url = "http://api.giphy.com/v1/gifs/random?q=#{keywords}&api_key=#{ENV.fetch('GIPHY_API_KEY', nil)}&rating=G"
    result = JSON.parse(Net::HTTP.get_response(URI.parse(url)).body)
    result['data']['images']['fixed_height']['url']
  rescue StandardError => e
    logger.warn "Giphy.random: #{e.message}"
    nil
  end
end
