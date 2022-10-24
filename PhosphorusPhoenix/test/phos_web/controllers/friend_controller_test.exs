defmodule PhosWeb.API.FriendControllerTest do
  use PhosWeb.ConnCase, async: true

  import Phos.UsersFixtures

  setup %{conn: conn} do
    {:ok, conn: conn
    |> put_req_header("accept", "application/json")}
  end

  describe "POST /api/folkland/friends" do
    setup [:inject_user_token]

    test "request friend relation", %{conn: conn} do
      friend = user_fixture()

      %{assigns: %{current_user: user}} = conn = post(conn, Routes.friend_path(conn, :create), %{"acceptor_id" => friend.id})
      assert %{"data" => data} = json_response(conn, 201)
      assert Map.get(data, "initiator_id") == user.id
      assert Map.get(data, "acceptor_id") == friend.id
    end

    test "cannot request friend relation when request to himself", %{conn: conn, user: user} do
      conn = post(conn, Routes.friend_path(conn, :create), %{"acceptor_id" => user.id})
      assert %{"message" => msg, "state" => state} = json_response(conn, 422)
      assert msg == "API not needed to connect to your own inner self"
      assert state == "error"
    end

    test "error request friend relation", %{conn: conn} do
      fake_uuid = "00000000-0000-0000-0000-000000000000"
      conn = post(conn, Routes.friend_path(conn, :create), %{"acceptor_id" => fake_uuid})
      assert %{"errors" => err} = json_response(conn, 422)
      assert Map.get(err, "acceptor_id") == ["does not exist"]
    end

    test "request friend relation twice", %{conn: conn} do
      friend = user_fixture()

      %{assigns: %{current_user: user}} = conn = post(conn, Routes.friend_path(conn, :create), %{"acceptor_id" => friend.id})
      assert %{"data" => data} = json_response(conn, 201)
      assert Map.get(data, "initiator_id") == user.id
      assert Map.get(data, "acceptor_id") == friend.id

      conn = post(conn, Routes.friend_path(conn, :create), %{"acceptor_id" => friend.id})
      assert %{"errors" => err} = json_response(conn, 422)
      Map.get(err, "branches")
      |> List.first()
      |> Map.get("user_id")
      |> Kernel.==(["already exists"])
      |> assert()
    end
  end

  describe "GET /api/folkland/friends" do
    setup [:inject_user_token]

    test "return empty list when no friends", %{conn: conn} do
      conn = get(conn, Routes.friend_path(conn, :index), %{"page" => 1})

      assert %{"data" => []} = json_response(conn, 200)
    end

    test "return friends list", %{conn: conn, user: user} do
      acceptor = Phos.UsersFixtures.user_fixture()
      assert {:ok, root} = Phos.Folk.add_friend(user.id, acceptor.id)
      assert {:ok, _data} = Phos.Folk.update_relation(root, %{"state" => "completed"})

      conn = get(conn, Routes.friend_path(conn, :index), %{"page" => 1})

      assert %{"data" => [rel]} = json_response(conn, 200)
      assert Map.get(rel, "acceptor_id") == acceptor.id
    end
  end

  describe "PUT /api/folkland/friends/accept" do
    setup [:inject_user_token]

    test "return relation detail when accepting friends", %{conn: conn, user: user} do
      initiator = Phos.UsersFixtures.user_fixture()

      assert {:ok, root} = Phos.Folk.add_friend(initiator.id, user.id)
      assert root.state == "requested"

      conn = put(conn, Routes.friend_path(conn, :accept), %{"relation_id" => root.id})

      assert %{"data" => relation} = json_response(conn, 200)
      assert Map.get(relation, "state") == "completed"
    end

    test "return unauthorized when not an acceptor", %{conn: conn, user: user} do
      acceptor = Phos.UsersFixtures.user_fixture()

      assert {:ok, root} = Phos.Folk.add_friend(user.id, acceptor.id)
      assert root.state == "requested"

      conn = put(conn, Routes.friend_path(conn, :accept), %{"relation_id" => root.id})

      assert "Forbidden" = json_response(conn, 401)
    end

    test "return error when already friends", %{conn: conn, user: user} do
      initiator = Phos.UsersFixtures.user_fixture()

      assert {:ok, root} = Phos.Folk.add_friend(initiator.id, user.id)
      assert {:ok, updated_relation} = Phos.Folk.update_relation(root, %{"state" => "completed"})
      assert updated_relation.state == "completed"

      conn = put(conn, Routes.friend_path(conn, :accept), %{"relation_id" => updated_relation.id})

      assert %{"messages" => [msg], "state" => state} = json_response(conn, 400)
      assert state == "error"
      assert msg == "state transition_changeset failed: invalid transition from completed to completed"
    end
  end

  describe "PUT /api/folkland/friends/reject" do
    setup [:inject_user_token]

    test "return relation detail when rejecting friends", %{conn: conn, user: user} do
      initiator = Phos.UsersFixtures.user_fixture()

      assert {:ok, root} = Phos.Folk.add_friend(initiator.id, user.id)
      assert root.state == "requested"

      conn = put(conn, Routes.friend_path(conn, :reject), %{"relation_id" => root.id})

      assert %{"data" => relation} = json_response(conn, 200)
      assert Map.get(relation, "state") == "ghosted"
    end

    test "return error when already friends and then reject", %{conn: conn, user: user} do
      initiator = Phos.UsersFixtures.user_fixture()

      assert {:ok, root} = Phos.Folk.add_friend(initiator.id, user.id)
      assert {:ok, updated_relation} = Phos.Folk.update_relation(root, %{"state" => "completed"})
      assert updated_relation.state == "completed"

      conn = put(conn, Routes.friend_path(conn, :reject), %{"relation_id" => updated_relation.id})

      assert %{"errors" => %{"state" => [msg]}} = json_response(conn, 422)
      assert msg == "transition_changeset failed: invalid transition from completed to ghosted"
    end
  end

end
