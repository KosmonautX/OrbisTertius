defmodule PhosWeb.OrbControllerTest do
  use PhosWeb.ConnCase

  import Phos.ActionFixtures

  alias Phos.Action

  @create_attrs_geohash_list %{
    id: "6304af82-088c-4383-ae23-e70ca7d9460d",
    title: "some title with geohash list",
    active: "true",
    "geolocation": %{"geohashes": [623275816647884799, 623275816649424895, 623275816649293823, 623275816647753727, 623275816647688191, 623275816647819263, 623275816648835071]},
    "active": "true",
    "media": "false",
    "expires_in": "10000"
  }

  @create_attrs_central_geohash %{
    id: "6304af82-088c-4383-ae23-e70ca7d9460d",
    title: "some title with central_geohash",
    active: "true",
    "geolocation": %{"central_geohash": 623275816647884799},
    "active": "true",
    "media": "false",
    "expires_in": "10000"
  }

  @update_attrs %{
    "active": "false",
    "title": "some updated title"
  }
  @invalid_attrs %{
    id: "6304af82-088c-4383-ae23-e70ca7d9460d",
    "media": "false",
  }

  setup %{conn: conn} do
    {:ok, conn: conn
    |> put_req_header("accept", "application/json")}
  end


  ## TODO add thetests on territory, and history

    describe "index" do
      setup [:inject_user_token]

      test "lists all orbs", %{conn: conn, user: user} do
        orb = orb_fixture(%{"initiator_id" => user.id})
        conn = get(conn, Routes.orb_path(conn, :index))

        assert [%{"orb_uuid" => id}] = json_response(conn, 200)["data"]

        assert [%{
          "orb_uuid" => ^id,
          "active" => true,
          "title" => "some title",
        }] = json_response(conn, 200)["data"]
      end
    end

  describe "create orb with target geohash" do
    setup [:inject_user_token]
    test "renders orb when data is valid", %{conn: conn} do
      conn = post(conn, Routes.orb_path(conn, :create), @create_attrs_central_geohash)
      assert %{"orb_uuid" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.orb_path(conn, :show, id))

      assert %{
               "orb_uuid" => ^id,
               "active" => true,
               "title" => "some title with central_geohash",
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.orb_path(conn, :create), @invalid_attrs)

      assert %{
        "title" => ["can't be blank"],
      } = json_response(conn, 422)["errors"]
    end
  end

  describe "create orb with geohash list" do
    setup [:inject_user_token]
    test "renders orb when data is valid", %{conn: conn, user: user} do
      conn = post(conn, Routes.orb_path(conn, :create), @create_attrs_geohash_list)
      assert %{"orb_uuid" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.orb_path(conn, :show, id))

      assert %{
               "orb_uuid" => ^id,
               "active" => true,
               "title" => "some title with geohash list",
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.orb_path(conn, :create), @invalid_attrs)

      assert %{
        "title" => ["can't be blank"],
      } = json_response(conn, 422)["errors"]
    end
  end

  describe "update orb" do
    setup [:inject_user_token]

    test "renders orb when data is valid", %{conn: conn, user: user} do
      orb = orb_fixture(%{"initiator_id" => user.id})
      conn = put(conn, Routes.orb_path(conn, :update, orb), @update_attrs)
      assert %{"orb_uuid" => id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.orb_path(conn, :show, id))

      assert %{
        "orb_uuid" => ^id,
        "active" => false,
        "title" => "some updated title"
      } = json_response(conn, 200)["data"]
    end

    ## TODO test errors on update functions

    # test "renders errors when data is invalid", %{conn: conn, user: user} do
    #   orb = orb_fixture(%{"initiator_id" => user.id})
    #   conn = put(conn, Routes.orb_path(conn, :update, orb), @invalid_attrs)

    #   assert %{
    #     "title" => ["can't be blank"],
    #   } = json_response(conn, 422)["errors"]
    # end
  end

  describe "delete orb" do
    setup [:inject_user_token]

    test "deletes chosen orb", %{conn: conn, user: user} do
      orb = orb_fixture(%{"initiator_id" => user.id})
      conn = delete(conn, Routes.orb_path(conn, :delete, orb))
      assert response(conn, 204)
      conn = get(conn, Routes.orb_path(conn, :show, orb))

      assert response conn, 404
    end
  end
end
