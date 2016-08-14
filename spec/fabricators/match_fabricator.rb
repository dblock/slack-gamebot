Fabricator(:match_lost_to, class_name: 'Match') do
  after_build do |match|
    match.scores = match.tied? ? [[3, 3]] : [[15, 21]]
  end
end

Fabricator(:match) do
  after_build do |match|
    match.challenge ||= Fabricate(:challenge, team: match.team || Team.first || Fabricate(:team))
    match.team = challenge.team
    match.winners = match.challenge.challengers if match.winners.none?
    match.losers = match.challenge.challenged if match.losers.none?
    match.scores = match.tied? ? [[3, 3]] : [[15, 21]]
  end
  after_create do |match|
    challenge.update_attributes!(state: ChallengeState::PLAYED, updated_by: match.losers.first)
  end
end
