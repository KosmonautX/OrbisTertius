defmodule PhosWeb.Util.ViewerTest do
  use Phos.DataCase

  alias Phoenix.View
  alias PhosWeb.Util.Viewer

  describe "orb_mapper/1" do
    orb_1 = orb_fixture(%{title: "First orb"})
    orb_2 = orb_fixture(%{title: "Second orb"})

    test "when given data is single orb" do
      keys = ~w(expiry_time active orb_uuid title relationship creationtime mutationtime source payload geolocation parent media)a
      assert data = Viewer.orb_mapper(orb_1)
      assert Enum.sort(Map.keys(data)) == Enum.sort(keys)
    end

    test "when given data is list" do
      data = [orb_1, orb_2]

      assert data = Viewer.orb_mapper(data)
      assert Kernel.length(data) == 2
    end
  end
  
end
