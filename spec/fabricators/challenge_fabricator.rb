Fabricator(:challenge) do
  challengers { [Fabricate(:user)] }
  challenged { [Fabricate(:user)] }
end
