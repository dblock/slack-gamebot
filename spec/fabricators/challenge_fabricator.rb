Fabricator(:challenge) do
  channel 'gamebot'
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
