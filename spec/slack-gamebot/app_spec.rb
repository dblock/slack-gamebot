require 'spec_helper'

describe SlackGamebot::App do
  def app
    SlackGamebot::App.new
  end
  it_behaves_like 'a slack ruby bot'
end
