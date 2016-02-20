Fabricator(:challenge) do
  channel 'gamebot'
  team { Team.first || Fabricate(:team) }
  before_create do |instance|
    instance.challengers << Fabricate(:user, team: instance.team) unless instance.challengers.any?
    instance.challenged << Fabricate(:user, team: instance.team) unless instance.challenged.any?
    instance.created_by = instance.challengers.first
  end
end

Fabricator(:doubles_challenge, from: :challenge) do
  after_build do |instance|
    instance.challengers = [Fabricate(:user, team: instance.team), Fabricate(:user, team: instance.team)] unless instance.challengers.any?
    instance.challenged = [Fabricate(:user, team: instance.team), Fabricate(:user, team: instance.team)] unless instance.challenged.any?
  end
end

Fabricator(:accepted_challenge, from: :challenge) do
  state ChallengeState::ACCEPTED
  before_create do |instance|
    instance.updated_by = instance.challenged.first
  end
end

Fabricator(:declined_challenge, from: :challenge) do
  state ChallengeState::DECLINED
  before_create do |instance|
    instance.updated_by = instance.challenged.first
  end
end

Fabricator(:canceled_challenge, from: :challenge) do
  state ChallengeState::CANCELED
  before_create do |instance|
    instance.updated_by = instance.challengers.first
  end
end

Fabricator(:played_challenge, from: :challenge) do
  state ChallengeState::PLAYED
  before_create do |instance|
    instance.updated_by = instance.challenged.first
  end
end

Fabricator(:automatch_challenge, from: :challenge) do
  state ChallengeState::ACCEPTED
  after_build do |instance|
    instance.challengers = [Fabricate(:user, team: instance.team), Fabricate(:user, team: instance.team)] unless instance.challengers.any?
    instance.challenged = [Fabricate(:user, team: instance.team), Fabricate(:user, team: instance.team)] unless instance.challenged.any?
  end
  before_create do |instance|
    instance.updated_by = instance.challenged.first
  end
end
