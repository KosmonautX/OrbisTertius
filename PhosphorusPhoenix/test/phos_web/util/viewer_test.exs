defmodule PhosWeb.Util.ViewerTest do
  use Phos.DataCase

  alias PhosWeb.Util.Viewer

  import Phos.ActionFixtures, only: [orb_fixture: 1]

  describe "orb_mapper/1" do
    test "when given data is single orb" do
      orb = orb_fixture(%{"title" => "First orb"})
      keys = ~w(expiry_time comment_count active orb_uuid title relationships creationtime mutationtime source payload geolocation parent media traits)a
      assert data = Viewer.orb_mapper(orb)
      assert Enum.sort(Map.keys(data)) == Enum.sort(keys)
    end

    test "when given data is list" do
      keys = ~w(expiry_time comment_count active orb_uuid title relationships creationtime mutationtime source payload geolocation parent media traits)a
      orb_1 = orb_fixture(%{"title" => "First orb"})
      orb_2 = orb_fixture(%{"title" => "Second orb"})
      data = [orb_1, orb_2]

      assert data = Viewer.orb_mapper(data)
      assert Kernel.length(data) == 2
      assert Enum.sort(Map.keys(List.first(data))) == Enum.sort(keys)
    end
  end
  
end
