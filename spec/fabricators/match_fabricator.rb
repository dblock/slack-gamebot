Fabricator(:match) do
  after_build do |match|
    match.challenge ||= Fabricate(:challenge, team: match.team || Team.first || Fabricate(:team))
    match.team = challenge.team
    match.winners = match.challenge.challengers if match.winners.none?
    match.losers = match.challenge.challenged if match.losers.none?
    match.scores = [[15, 21]]
  end
  after_create do |match|
    match.winners.inc(wins: 1)
    match.losers.inc(losses: 1)
    User.rank!(match.team)
    challenge.update_attributes!(state: ChallengeState::PLAYED, updated_by: match.losers.first)
  end
end
