Fabricator(:challenge) do
  channel 'gamebot'
  team { Team.first || Fabricate(:team) }
  challengers { [Fabricate(:user)] }
  challenged { [Fabricate(:user)] }
  before_create do |instance|
    instance.created_by = instance.challengers.first
  end
end

Fabricator(:doubles_challenge, from: :challenge) do
  challengers { [Fabricate(:user), Fabricate(:user)] }
  challenged { [Fabricate(:user), Fabricate(:user)] }
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
