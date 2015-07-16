Fabricator(:season) do
  before_validation do
    Fabricate(:match) if Challenge.current.none?
  end
end
