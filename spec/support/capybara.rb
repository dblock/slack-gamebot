require 'capybara/rspec'

Capybara.register_driver :selenium_no_wait do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.page_load_strategy = :none
  Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
end

Capybara.configure do |config|
  config.app = Api::Middleware.instance
  config.server_port = 9293
  config.server = :puma
end

module Capybara
  module Node
    class Element
      def client_set(value)
        driver.browser.execute_script("$(arguments[0]).val('#{value}');", native)
      end
    end
  end
end
