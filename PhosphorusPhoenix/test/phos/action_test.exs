defmodule Phos.ActionTest do
  use Phos.DataCase

  alias Phos.Action

  describe "orbs" do
    alias Phos.Action.Orb
    import Phos.ActionFixtures
    import Phos.UsersFixtures


    @invalid_attrs %{active: nil, extinguish: nil, media: nil, title: nil}

    test "list_orbs/0 returns all orbs" do
      orb = orb_fixture()
      assert Action.list_orbs() |> Phos.Repo.preload([:locations,:initiator]) == [orb]
    end

    test "get_orb!/1 returns the orb with given id" do
      orb = orb_fixture()
      assert Action.get_orb!(orb.id) == orb
    end

    test "create_orb/1 with valid data creates a orb" do
      valid_attrs = %{id: Ecto.UUID.generate(), active: true, extinguish: ~N[2022-05-20 12:12:00], media: true, title: "some title"}

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
      %{id: user_id} = user = user_fixture()
      update_attrs = %{initiator: user_id, active: false, extinguish: ~N[2022-05-21 12:12:00], media: false, title: "some updated title"}

      assert {:ok, %Orb{} = orb} = Action.update_orb(orb, update_attrs)
      assert orb.active == false
      assert orb.extinguish == ~N[2022-05-21 12:12:00]
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
  end
end
