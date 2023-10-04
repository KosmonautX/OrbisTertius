defmodule Phos.ActionTest do
  use Phos.DataCase

  alias Phos.Action
  alias Phos.Action.Orb

  import Phos.ActionFixtures
  import Phos.UsersFixtures

  describe "orbs" do
    @invalid_attrs %{active: nil, extinguish: nil, media: nil, title: nil}

    test "list_orbs/0 returns all orbs" do
      orb = orb_fixture()
      assert Action.list_orbs() |> Phos.Repo.preload([:locations,:initiator]) == [orb]
    end

    test "get_orb/1 return specific orb" do
      %{id: id} = orb_fixture()

      assert {:ok, %Orb{} = orb} = Action.get_orb(id)
      assert orb.id == id
      assert Map.get(orb, :number_of_repost)
      assert Map.get(orb, :comment_count)
    end

    test "get_orb!/1 returns the orb with given id" do
      orb = orb_fixture()
      assert Action.get_orb!(orb.id) == orb
    end

    test "create_orb/1 with valid data creates a orb" do
      %{id: user_id} = user_fixture()
      valid_attrs = %{id: Ecto.UUID.generate(), active: true, extinguish: ~N[2022-05-20 12:12:00], media: true, initiator_id: user_id, title: "some title"}

      assert {:ok, %Orb{} = orb} = Action.create_orb(valid_attrs)
      assert orb.active == true
      assert orb.extinguish == ~N[2022-05-20 12:12:00]
      assert orb.media == true
      assert orb.title == "some title"
    end

    test "create_orb/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Action.create_orb(@invalid_attrs)
    end

    test "update_orb/2 with valid data updates the orb" do
      orb = orb_fixture_no_location()
      %{id: user_id} = user_fixture()
      update_attrs = %{initiator: user_id, active: false, media: false, title: "some updated title"}

      assert {:ok, %Orb{} = orb} = Action.update_orb(orb, update_attrs)
      assert orb.active == false
      assert orb.media == false
      assert orb.title == "some updated title"
    end

    test "update_orb/2 with invalid data returns error changeset" do
      orb = orb_fixture_no_location()
      assert {:error, %Ecto.Changeset{}} = Action.update_orb(orb, @invalid_attrs)
      assert orb == Action.get_orb!(orb.id)
    end

    test "delete_orb/1 deletes the orb" do
      orb = orb_fixture()
      assert {:ok, %Orb{}} = Action.delete_orb(orb)
      assert_raise Ecto.NoResultsError, fn -> Action.get_orb!(orb.id) end
    end

    test "change_orb/1 returns a orb changeset" do
      orb = orb_fixture()
      assert %Ecto.Changeset{} = Action.change_orb(orb)
    end

    test "get_orb_by_trait_geo/3 returns list orb location with included traits" do
      orb = orb_fixture(%{
        "traits" => ["sample", "test"],
        "locations" => 
          [12_345_678_901_234]
          |> Enum.map(fn v -> %{"id" => v} end)})

      assert orbs = Action.get_orb_by_trait_geo([12_345_678_901_234], ["sample"])
      assert length(orbs) == 1
      assert List.first(orbs).orb_id == orb.id
    end

    test "get_orb_by_trait_geo/3 returns list orb with one traits" do
      orb = orb_fixture(%{
        "traits" => ["sample", "test"],
        "locations" => 
          [12_345_678_901_234]
          |> Enum.map(fn v -> %{"id" => v} end)})

      assert orbs = Action.get_orb_by_trait_geo([12_345_678_901_234], "sample")
      assert length(orbs) == 1
      assert List.first(orbs).orb_id == orb.id
    end

    test "filter_orbs_by_traits/2 return list orbs filtered by tratis" do
      orb = orb_fixture(%{"traits" => ["trait", "test"]})

      assert orbs = Action.filter_orbs_by_traits(["test"])
      assert length(orbs.data) == 1
      assert List.first(orbs.data).id == orb.id
    end
  end

  describe "reorb" do
    test "reorb/2 with no comment" do
      orb = orb_fixture_no_location()
      %{id: user_id} = user_fixture()

      {:ok, reorb} = Action.reorb(user_id, orb.id)
      assert reorb.parent_id == orb.id
      assert reorb.path
      assert Kernel.length(reorb.path.labels) == 2
      assert [parent_id, child_id] = reorb.path.labels
      assert parent_id == String.replace(orb.id, "-", "")
      assert child_id == String.replace(reorb.id, "-", "")

      {:ok, parent_orb} = Action.get_orb(orb.id)
      assert parent_orb.number_of_repost == 1
    end

    test "reorb/3 with comment" do
      orb = orb_fixture_no_location()
      message = "This is re post message"
      %{id: user_id} = user_fixture()

      {:ok, reorb} = Action.reorb(user_id, orb.id, message)
      assert reorb.parent_id == orb.id
      assert reorb.title == message
      assert reorb.path
      assert Kernel.length(reorb.path.labels) == 2
      assert [parent_id, child_id] = reorb.path.labels
      assert parent_id == String.replace(orb.id, "-", "")
      assert child_id == String.replace(reorb.id, "-", "")

      {:ok, parent_orb} = Action.get_orb(orb.id)
      assert parent_orb.number_of_repost == 1
    end

    test "reorb/2 with multiple repost" do
      orb = orb_fixture_no_location()
      %{id: user_id_1} = user_fixture()
      %{id: user_id_2} = user_fixture()

      {:ok, reorb_1} = Action.reorb(user_id_1, orb.id)
      assert reorb_1.parent_id == orb.id
      assert reorb_1.path

      {:ok, reorb_2} = Action.reorb(user_id_2, reorb_1.id)
      assert reorb_2.parent_id == reorb_1.id
      assert reorb_2.path
      assert Kernel.length(reorb_2.path.labels) == 3
      assert [parent_id, intermediette_id, child_id] = reorb_2.path.labels
      assert parent_id == String.replace(orb.id, "-", "")
      assert intermediette_id == String.replace(reorb_1.id, "-", "")
      assert child_id == String.replace(reorb_2.id, "-", "")

      {:ok, parent_orb} = Action.get_orb(orb.id)
      assert parent_orb.number_of_repost == 1

      {:ok, reorb_1} = Action.get_orb(reorb_1.id)
      assert reorb_1.number_of_repost == 1
    end
  end

  describe "blorbs" do
    alias Phos.Action.Blorb

    import Phos.ActionFixtures

    @invalid_attrs %{}

    test "list_blorbs/0 returns all blorbs" do
      blorb = blorb_fixture()
      assert Action.list_blorbs() == [blorb]
    end

    test "get_blorb!/1 returns the blorb with given id" do
      blorb = blorb_fixture()
      assert Action.get_blorb!(blorb.id) == blorb
    end

    test "create_blorb/1 with valid data creates a blorb" do
      valid_attrs = %{}

      assert {:ok, %Blorb{} = blorb} = Action.create_blorb(valid_attrs)
    end

    test "create_blorb/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Action.create_blorb(@invalid_attrs)
    end

    test "update_blorb/2 with valid data updates the blorb" do
      blorb = blorb_fixture()
      update_attrs = %{}

      assert {:ok, %Blorb{} = blorb} = Action.update_blorb(blorb, update_attrs)
    end

    test "update_blorb/2 with invalid data returns error changeset" do
      blorb = blorb_fixture()
      assert {:error, %Ecto.Changeset{}} = Action.update_blorb(blorb, @invalid_attrs)
      assert blorb == Action.get_blorb!(blorb.id)
    end

    test "delete_blorb/1 deletes the blorb" do
      blorb = blorb_fixture()
      assert {:ok, %Blorb{}} = Action.delete_blorb(blorb)
      assert_raise Ecto.NoResultsError, fn -> Action.get_blorb!(blorb.id) end
    end

    test "change_blorb/1 returns a blorb changeset" do
      blorb = blorb_fixture()
      assert %Ecto.Changeset{} = Action.change_blorb(blorb)
    end
  end
end
