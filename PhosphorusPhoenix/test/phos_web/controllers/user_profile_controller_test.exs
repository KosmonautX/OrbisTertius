defmodule PhosWeb.UserProfileControllerTest do
  use PhosWeb.ConnCase

  import Phos.ActionFixtures

  @create_attrs %{
    "territory": [
      %{
          "id" => "home",
          "geohash" => 627779412520177663,
          "location_description" => "Keong Saik"
      }
    ]
  }

  @update_attrs %{
    "territory": [
      %{
        "id" => "home",
        "geohash" => 627779412520177663,
        "location_description" => "Keong Saik"
      },
      %{
        "id" => "work",
        "geohash" => 627779410029711359,
        "location_description" => "Bukit Panjang",
      }
    ]
  }

  @invalid_geohash_attrs %{
    "territory": [
      %{
          "id" => "work",
          "geohash" => 162779410029711359,
          "location_description" => "Bukit Panjang"
      }
    ]
  }

  @invalid_atomkey__attrs %{
    "territory": [
      %{
          id: "work",
          geohash: 627779410029711359,
          location_description: "Bukit Panjang"
      }
    ]
  }

  setup %{conn: conn} do
    {:ok, conn: conn
    |> put_req_header("accept", "application/json")}
  end

  describe "index" do
    setup [:inject_user_token]

    test "update self territory with no existing geolocation", %{conn: conn, user: user} do

      conn = put(conn, ~p"/api/userland/self/territory", @create_attrs)
      assert %{"profile" => %{"private" => %{"data" => %{"geolocation" => geolocation}}}} = json_response(conn, 200)["data"]
      assert [%{
        "id" => "home",
        "geohash" => 627779412520177663,
        "location_description" => "Keong Saik",
      }] = geolocation
    end

    test "update self territory with existing geolocation", %{conn: conn, user: user} do
      conn = put(conn, ~p"/api/userland/self/territory", @update_attrs)
      assert %{"profile" => %{"private" => %{"data" => %{"geolocation" => geolocation}}}} = json_response(conn, 200)["data"]
      assert [
        %{
          "id" => "home",
          "geohash" => 627779412520177663,
          "location_description" => "Keong Saik"
        },
        %{
          "id" => "work",
          "geohash" => 627779410029711359,
          "location_description" => "Bukit Panjang",
        }
      ] = geolocation
    end

    test "update self territory using same geohashes", %{conn: conn, user: user} do
      conn = put(conn, ~p"/api/userland/self/territory", @update_attrs)
      assert %{"profile" => %{"private" => %{"data" => %{"geolocation" => geolocation}}}} = json_response(conn, 200)["data"]
      assert [
        %{
          "id" => "home",
          "geohash" => 627779412520177663,
          "location_description" => "Keong Saik"
        },
        %{
          "id" => "work",
          "geohash" => 627779410029711359,
          "location_description" => "Bukit Panjang",
        }
      ] = geolocation

      conn = put(conn, ~p"/api/userland/self/territory", @update_attrs)
      assert %{"profile" => %{"private" => %{"data" => %{"geolocation" => geolocation}}}} = json_response(conn, 200)["data"]
    end

    test "update self territory with invalid geohash", %{conn: conn, user: user} do
      conn = put(conn, ~p"/api/userland/self/territory", @invalid_geohash_attrs)
      assert %{"errors" => %{"message" => "Unprocessable Entity"}} = json_response(conn, 422)
    end
  end
end
