require 'spec_helper'

describe SlackGamebot::Commands::Unknown do
  it 'invalid command' do
    expect(message: 'gamebot foobar').to respond_with_error("Sorry <@user>, I don't understand that command!")
  end
end
