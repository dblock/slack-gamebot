require 'sinatra/base'
require File.expand_path('../config/environment', __FILE__)

module SlackGamebot
  class Web < Sinatra::Base
    get '/' do
      'SlackGamebot'
    end
  end
end
