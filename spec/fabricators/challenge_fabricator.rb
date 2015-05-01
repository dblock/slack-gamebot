Fabricator(:challenge) do
  challengers { [Fabricate(:user)] }
  challenged { [Fabricate(:user)] }
end

Fabricator(:doubles_challenge, from: :challenge) do
  challengers { [Fabricate(:user), Fabricate(:user)] }
  challenged { [Fabricate(:user), Fabricate(:user)] }
end
