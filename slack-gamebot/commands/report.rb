module SlackGamebot
  module Commands
    class Report < SlackRubyBot::Commands::Base
      class << self
        # pongbot report @opponent a1:b1 a2:b2 a3:b3
        # where a# is your score, and b# is your opponent's score
        def call(client, data, _match)
          # auto-register people, because that step is annoying
          ensure_both_users_are_registered!(client, data, _match)

          # auto-challenge-and accept, because this step is silly
          setup_match

          # finally, record the score. Hooray, we skipped all the annoying stuff
          record_score
        end

        def ensure_both_users_are_registered!
          current_user = Register.call(client, data, _match)
          # TODO: implement this
        end

        def setup_match

        end

        def record_score

        end
      end
    end
  end
end
