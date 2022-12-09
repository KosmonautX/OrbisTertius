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
      refute reorb.comment_id

      {:ok, parent_orb} = Action.get_orb(orb.id)
      assert parent_orb.number_of_repost == 1
    end

    test "reorb/3 with comment" do
      orb = orb_fixture_no_location()
      message = "This is re post message"
      %{id: user_id} = user_fixture()

      {:ok, reorb} = Action.reorb(user_id, orb.id, message)
      assert reorb.parent_id == orb.id
      assert reorb.path
      assert Kernel.length(reorb.path.labels) == 2
      assert [parent_id, child_id] = reorb.path.labels
      assert parent_id == String.replace(orb.id, "-", "")
      assert child_id == String.replace(reorb.id, "-", "")
      assert reorb.comment_id

      {:ok, parent_orb} = Action.get_orb(orb.id)
      assert parent_orb.number_of_repost == 1
      assert parent_orb.comment_count == 1
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
      assert parent_orb.number_of_repost == 2
    end
  end
end
