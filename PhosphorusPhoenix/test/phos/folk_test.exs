defmodule Phos.FolkTest do
  use Phos.DataCase

  alias Phos.Folk
  alias Phos.Users.RelationRoot

  describe "get_relation!/1" do
    test "return the user relation" do
      # assert %RelationRook{id: id} = Folk.get_relation!(user_id)
    end
  end

  describe "add_friend/1" do
    test "return relation scheme" do
      initiator = Phos.UsersFixtures.user_fixture()
      acceptor = Phos.UsersFixtures.user_fixture()

      assert {:ok, %RelationRoot{} = relation} = Folk.add_friend(initiator.id, acceptor.id)
      assert relation.acceptor_id == acceptor.id
      assert relation.initiator_id == initiator.id
    end

    test "return error when have the same id" do
      initiator = Phos.UsersFixtures.user_fixture()

      assert {:error, message} = Folk.add_friend(initiator.id, initiator.id)
      assert message == "API not needed to connect to your own inner self"
    end

    test "return error when user not found" do
      fake_uuid = "00000000-0000-0000-0000-000000000000"
      initiator = Phos.UsersFixtures.user_fixture()

      assert {:error, %Ecto.Changeset{} = message} = Folk.add_friend(initiator.id, fake_uuid)
      assert %{acceptor_id: msg} = errors_on(message)
      assert Kernel.length(msg) == 1
      assert Enum.at(msg, 0) == "does not exist"
    end
  end

  describe "pending_requests/4" do
    test "return empty list of pending relation" do
      user = Phos.UsersFixtures.user_fixture()
      assert %{data: [], meta: %{pagination: pagination}} = Folk.pending_requests(user)
      assert Map.get(pagination, :current) == 1
    end

    test "return list of pending relation" do
      user = Phos.UsersFixtures.user_fixture()
      assert %{data: [], meta: %{pagination: pagination}} = Folk.pending_requests(user)
      assert Map.get(pagination, :current) == 1

      acceptor = Phos.UsersFixtures.user_fixture()
      assert {:ok, %RelationRoot{}} = Folk.add_friend(user.id, acceptor.id)

      assert %{data: [rel], meta: %{pagination: pagination}} = Folk.pending_requests(user)
      assert Map.get(pagination, :current) == 1
      assert rel.acceptor_id == acceptor.id
    end
  end

  describe "friend_requests/4" do
    test "return empty list of friend request" do
      user = Phos.UsersFixtures.user_fixture()
      assert %{data: [], meta: %{pagination: pagination}} = Folk.friend_requests(user)
      assert Map.get(pagination, :current) == 1
    end

    test "return list of friend_requests" do
      user = Phos.UsersFixtures.user_fixture()
      assert %{data: [], meta: %{pagination: pagination}} = Folk.friend_requests(user)
      assert Map.get(pagination, :current) == 1

      initiator = Phos.UsersFixtures.user_fixture()
      assert {:ok, %RelationRoot{}} = Folk.add_friend(initiator.id, user.id)

      assert %{data: [rel], meta: %{pagination: pagination}} = Folk.friend_requests(user)
      assert Map.get(pagination, :current) == 1
      assert rel.initiator_id == initiator.id
    end
  end

  describe "friends/4" do
    test "return empty list of friends" do
      user = Phos.UsersFixtures.user_fixture()
      assert %{data: [], meta: %{pagination: pagination}} = Folk.friends(user)
      assert Map.get(pagination, :current) == 1
    end

    test "return list of friend_requests" do
      user = Phos.UsersFixtures.user_fixture()
      initiator = Phos.UsersFixtures.user_fixture()

      assert {:ok, %RelationRoot{} = root} = Folk.add_friend(initiator.id, user.id)
      assert {:ok, %RelationRoot{}} = Folk.update_relation(root, %{"state" => "completed"})

      # acceptor view
      assert %{data: [rel], meta: %{pagination: pagination}} = Folk.friends(user)
      assert Map.get(pagination, :current) == 1
      assert rel.id == initiator.id

      # initiator view
      assert %{data: [relation], meta: %{pagination: pagination}} = Folk.friends(initiator)
      assert Map.get(pagination, :current) == 1
      assert relation.id == user.id
    end
  end

  describe "friends_lite/1" do
    test "return empty list of friends" do
      user = Phos.UsersFixtures.user_fixture()
      assert [] = Folk.friends_lite(user.id)
    end

    test "return list of friends" do
      user = Phos.UsersFixtures.user_fixture()
      initiator = Phos.UsersFixtures.user_fixture()

      assert {:ok, %RelationRoot{} = root} = Folk.add_friend(initiator.id, user.id)
      assert {:ok, %RelationRoot{}} = Folk.update_relation(root, %{"state" => "completed"})

      assert [friend_id] = Folk.friends_lite(user.id)
      assert friend_id == initiator.id
    end
  end
end
