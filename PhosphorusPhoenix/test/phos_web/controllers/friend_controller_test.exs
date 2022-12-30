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

      %{assigns: %{current_user: user}} = conn = post(conn, ~p"/api/folkland/friends", %{"acceptor_id" => friend.id})
      assert %{"data" => data} = json_response(conn, 201)
      assert Map.get(data, "initiator_id") == user.id
      assert Map.get(data, "acceptor_id") == friend.id
    end

    test "cannot request friend relation when request to himself", %{conn: conn, user: user} do
      conn = post(conn, ~p"/api/folkland/friends", %{"acceptor_id" => user.id})
      assert %{"message" => msg, "state" => state} = json_response(conn, 422)
      assert msg == "API not needed to connect to your own inner self"
      assert state == "error"
    end

    test "error request friend relation", %{conn: conn} do
      fake_uuid = "00000000-0000-0000-0000-000000000000"
      conn = post(conn, ~p"/api/folkland/friends", %{"acceptor_id" => fake_uuid})
      assert %{"errors" => err} = json_response(conn, 422)
      assert Map.get(err, "acceptor_id") == ["does not exist"]
    end

    test "request friend relation twice", %{conn: conn} do
      friend = user_fixture()

      %{assigns: %{current_user: user}} = conn = post(conn, ~p"/api/folkland/friends", %{"acceptor_id" => friend.id})
      assert %{"data" => data} = json_response(conn, 201)
      assert Map.get(data, "initiator_id") == user.id
      assert Map.get(data, "acceptor_id") == friend.id

      conn = post(conn, ~p"/api/folkland/friends", %{"acceptor_id" => friend.id})
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
      conn = get(conn, ~p"/api/folkland/friends", %{"page" => 1})

      assert %{"data" => []} = json_response(conn, 200)
    end

    test "return friends list", %{conn: conn, user: user} do
      acceptor = Phos.UsersFixtures.user_fixture()
      assert {:ok, root} = Phos.Folk.add_friend(user.id, acceptor.id)
      assert {:ok, _data} = Phos.Folk.update_relation(root, %{"state" => "completed"})

      conn = get(conn, ~p"/api/folkland/friends", %{"page" => 1})

      assert %{"data" => [rel]} = json_response(conn, 200)
      assert Map.get(rel, "id") == acceptor.id
    end
  end

  describe "GET /api/folkland/self/pending" do
    setup [:inject_user_token]

    test "return empty list when no friends", %{conn: conn} do
      conn = get(conn, ~p"/api/folkland/self/pending", %{"page" => 1})

      assert %{"data" => []} = json_response(conn, 200)
    end

    test "return pending friends list", %{conn: conn, user: user} do
     acceptor = Phos.UsersFixtures.user_fixture()
      assert {:ok, _root} = Phos.Folk.add_friend(user.id, acceptor.id)

      conn = get(conn, ~p"/api/folkland/self/pending", %{"page" => 1})

      assert %{"data" => [rel]} = json_response(conn, 200)
      assert Map.get(rel, "acceptor_id") == acceptor.id
    end
  end

  describe "GET /api/folkland/self/requests" do
    setup [:inject_user_token]

    test "return empty list when no friends requests", %{conn: conn} do
      conn = get(conn, ~p"/api/folkland/self/requests", %{"page" => 1})

      assert %{"data" => []} = json_response(conn, 200)
    end

    test "return pending friends list", %{conn: conn, user: user} do
      initiator = Phos.UsersFixtures.user_fixture()
      assert {:ok, _root} = Phos.Folk.add_friend(initiator.id, user.id)

      conn = get(conn, ~p"/api/folkland/self/requests", %{"page" => 1})

      assert %{"data" => [rel]} = json_response(conn, 200)
      assert Map.get(rel, "initiator_id") == initiator.id
    end
  end

  describe "GET /api/folkland/others/:id" do
    setup [:inject_user_token]

    test "return empty list when no friends in other user", %{conn: conn} do
      stranger = Phos.UsersFixtures.user_fixture()
      conn = get(conn, ~p"/api/folkland/others/#{stranger.id}", %{"page" => 1})

      assert %{"data" => []} = json_response(conn, 200)
    end

    test "return friends list", %{conn: conn, user: user} do
      acceptor = Phos.UsersFixtures.user_fixture()
      assert {:ok, root} = Phos.Folk.add_friend(user.id, acceptor.id)
      assert {:ok, _data} = Phos.Folk.update_relation(root, %{"state" => "completed"})

      conn = get(conn, ~p"/api/folkland/others/#{acceptor.id}", %{"page" => 1})

      assert %{"data" => [rel]} = json_response(conn, 200)
      rel
      |> get_in(["id"])
      |> Kernel.==(user.id)
      |> assert()
    end

    test "return friends list as initiator", %{conn: conn, user: user} do
      initiator = Phos.UsersFixtures.user_fixture()
      assert {:ok, root} = Phos.Folk.add_friend(initiator.id, user.id)
      assert {:ok, _data} = Phos.Folk.update_relation(root, %{"state" => "completed"})

      conn = get(conn, ~p"/api/folkland/others/#{initiator.id}", %{"page" => 1})

      assert %{"data" => [rel]} = json_response(conn, 200)
      rel
      |> get_in(["id"])
      #|> get_in(["relationships", "self", "data", "initiator_id"])
      |> Kernel.==(user.id)
      |> assert()
    end
  end

  describe "PUT /api/folkland/friends/accept" do
    setup [:inject_user_token]

    test "return relation detail when accepting friends", %{conn: conn, user: user} do
      initiator = Phos.UsersFixtures.user_fixture()

      assert {:ok, root} = Phos.Folk.add_friend(initiator.id, user.id)
      assert root.state == "requested"

      conn = put(conn, ~p"/api/folkland/friends/accept", %{"relation_id" => root.id})

      assert %{"data" => relation} = json_response(conn, 200)
      assert Map.get(relation, "state") == "completed"
    end

    test "return unauthorized when not an acceptor", %{conn: conn, user: user} do
      acceptor = Phos.UsersFixtures.user_fixture()

      assert {:ok, root} = Phos.Folk.add_friend(user.id, acceptor.id)
      assert root.state == "requested"

      conn = put(conn, ~p"/api/folkland/friends/accept", %{"relation_id" => root.id})

      assert %{"errors" => %{"message" => "Forbidden"}} = json_response(conn, 401)
    end

    test "return error when already friends", %{conn: conn, user: user} do
      initiator = Phos.UsersFixtures.user_fixture()

      assert {:ok, root} = Phos.Folk.add_friend(initiator.id, user.id)
      assert {:ok, updated_relation} = Phos.Folk.update_relation(root, %{"state" => "completed"})
      assert updated_relation.state == "completed"

      conn = put(conn, ~p"/api/folkland/friends/accept", %{"relation_id" => updated_relation.id})

      assert %{"messages" => [msg], "state" => state} = json_response(conn, 400)
      assert state == "error"
      assert msg == "state transition_changeset failed: invalid transition from completed to completed"
    end
  end

  describe "PUT /api/folkland/friends/block" do
    setup [:inject_user_token]

    test "return relation detail when blocking friends", %{conn: conn, user: user} do
      initiator = Phos.UsersFixtures.user_fixture()

      assert {:ok, root} = Phos.Folk.add_friend(initiator.id, user.id)
      assert root.state == "requested"

      conn = put(conn, ~p"/api/folkland/friends/block", %{"relation_id" => root.id})

      assert %{"data" => relation} = json_response(conn, 200)
      assert Map.get(relation, "state") == "blocked"
    end

    test "return error when already friends and then block", %{conn: conn, user: user} do
      initiator = Phos.UsersFixtures.user_fixture()

      assert {:ok, root} = Phos.Folk.add_friend(initiator.id, user.id)
      assert {:ok, updated_relation} = Phos.Folk.update_relation(root, %{"state" => "completed"})
      assert updated_relation.state == "completed"

      conn = put(conn, ~p"/api/folkland/friends/block", %{"relation_id" => updated_relation.id})

      assert %{"errors" => %{"state" => [msg]}} = json_response(conn, 422)
      assert msg == "transition_changeset failed: invalid transition from completed to blocked"
    end
  end

  describe "DELETE /api/folkland/friends/:id" do
    setup [:inject_user_token]

    test "return relation detail when delete requested relation", %{conn: conn, user: user} do
      initiator = Phos.UsersFixtures.user_fixture()

      assert {:ok, root} = Phos.Folk.add_friend(initiator.id, user.id)
      assert root.state == "requested"

      conn = delete(conn, ~p"/api/folkland/friends/#{root.id}")

      assert %{"data" => relation} = json_response(conn, 200)
      assert Map.get(relation, "state") == "requested"
    end

    test "return relation detail when delete complete relation", %{conn: conn, user: user} do
      initiator = Phos.UsersFixtures.user_fixture()

      assert {:ok, root} = Phos.Folk.add_friend(initiator.id, user.id)
      assert {:ok, updated_relation} = Phos.Folk.update_relation(root, %{"state" => "completed"})
      assert updated_relation.state == "completed"

      conn = delete(conn, ~p"/api/folkland/friends/#{updated_relation.id}")

      assert %{"data" => relation} = json_response(conn, 200)
      assert Map.get(relation, "state") == "completed"
    end
  end
end
