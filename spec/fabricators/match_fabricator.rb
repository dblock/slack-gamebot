Fabricator(:match) do
  challenge { Fabricate(:challenge) }
  after_build do |match|
    match.winners = match.challenge.challengers if match.winners.none?
    match.losers = match.challenge.challenged if match.losers.none?
  end
end
