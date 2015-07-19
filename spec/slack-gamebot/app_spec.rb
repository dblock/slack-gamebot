require 'spec_helper'

describe SlackGamebot::App do
  let(:app) { SlackGamebot::App.new }
  it_behaves_like 'a slack ruby bot'
end
