Fabricator(:season) do
  team { Team.first || Fabricate(:team) }
  before_create do
    Fabricate(:match, team: team) if Challenge.current.none?
  end
end
