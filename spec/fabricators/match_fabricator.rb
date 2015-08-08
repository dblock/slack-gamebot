Fabricator(:match) do
  challenge { Fabricate(:challenge) }
  after_build do |match|
    match.winners = match.challenge.challengers if match.winners.none?
    match.losers = match.challenge.challenged if match.losers.none?
    match.scores = [[15, 21]]
  end
  after_create do |match|
    match.winners.inc(wins: 1)
    match.losers.inc(losses: 1)
    challenge.update_attributes!(state: ChallengeState::PLAYED, updated_by: match.losers.first)
  end
end
