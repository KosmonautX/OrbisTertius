defmodule PhosWeb.OrbLiveTest do
  use PhosWeb.ConnCase
  alias Phos.Users
  import Phoenix.LiveViewTest
  import Phos.ActionFixtures

  @create_attrs %{"title" => "some title", "extinguish" => "2022-12-02T13:31:00", "source" => :web, "location" => :home, "radius" => 8, "payload" => %{"info" => "some info", "tip" => "some tip", "when" => "some when", "where" => "some where"}}
  @update_attrs %{"title" => "updated title", "active" => true, "extinguish" => "2022-12-02T13:31:00", "source" => :web, "location" => :home, "radius" => 8, "payload" => %{"info" => "updated info", "tip" => "updated tip", "when" => "updated when", "where" => "updated where"}}
  #@invalid_attrs %{"active" => true, "extinguish" => %{day: 21, hour: 7, minute: 22, month: 5, year: 2022}, "source" => :web, "location" => :home, "radius" => 8, "payload" => %{"info" => "some info", "tip" => "some tip", "when" => "some when", "where" => "some where"}}
  @no_location_update_attrs %{"title" => "updated title", "active" => true, "extinguish" => "2022-12-02T13:31:00", "source" => :web, "radius" => 8, "payload" => %{"info" => "updated info", "tip" => "updated tip", "when" => "updated when", "where" => "updated where"}}
  # @create_attrs %{active: true, extinguish: %{day: 21, hour: 7, minute: 22, month: 5, year: 2022}, media: true, title: "some title"}
  # @update_attrs %{active: false, extinguish: %{day: 22, hour: 7, minute: 22, month: 5, year: 2022}, media: false, title: "some updated title"}
  # @invalid_attrs %{active: false, extinguish: %{day: 30, hour: 7, minute: 22, month: 2, year: 2022}, media: false, title: nil}

  defp create_orb(_) do
    orb = orb_fixture()
    %{orb: orb}
  end

  # defp create_pte_profile(_) do
  #   user = user_pte_prof_fixture(%{id: "home", geohash: 623276216934563839, chronolock: 1653079771, location_description: nil})
  #   %{user: user}
  # end

  describe "Index" do
    setup [:create_orb, :register_and_log_in_user]
    # setup [:create_orb, :create_pte_profile]

    test "lists all orbs", %{conn: conn, user: user} do
      %Users.Private_Profile{}
        |> Users.Private_Profile.changeset(%{user_id: user.id})
        |> Ecto.Changeset.put_embed(:geolocation, [%{id: "home", geohash: 623276216934563839, chronolock: 1653079771, location_description: nil}])
        |> Phos.Repo.insert()
      {:ok, index_live, _html} = live(conn, ~p"/orb")

      send(index_live.pid, {:static_location_update, %{"locname" => :work, "longitude" => 103.96218306516853, "latitude" => 1.3395765950767413}})
      _ = :sys.get_state(index_live.pid)

      assert render(index_live) =~ "some title"

  #     {:ok, view, html} =
  #       conn
  # |> put_connect_params(%{"param" => "value"})
  # |> live_isolated(PhosWeb.OrbLive.MapComponent)
  #     assert view |> render_hook("save_loc", %{"lng" => 103.96218306516853, "lat" => 1.3395765950767413}) =~"some title"

    end

    test "saves new orb", %{conn: conn, user: user} do
      {:ok, _ecto_insert} =
        %Users.Private_Profile{}
        |> Users.Private_Profile.changeset(%{user_id: user.id})
        |> Ecto.Changeset.put_embed(:geolocation, [%{id: "home", geohash: 623276216934563839, chronolock: 1653079771, location_description: nil}])
        |> Phos.Repo.insert()

      {:ok, index_live, _html} = live(conn, ~p"/orb")
      assert index_live |> element("a", "New Orb") |> render_click() =~
               "New Orb"

      assert_patch(index_live, ~p"/orb/new")

      {:ok, index_live, html} =
        index_live
        |> form("#orb-form", orb: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/orb")

      assert html =~ "Orb created successfully"
      assert render_hook(index_live, "live_location_update", %{"longitude" => 103.96218306516853, "latitude" => 1.3395765950767413}) =~ "some title"
    end

    test "updates orb in listing", %{conn: conn, orb: orb, user: user} do
      {:ok, _ecto_insert} =
        %Users.Private_Profile{}
        |> Users.Private_Profile.changeset(%{user_id: user.id})
        |> Ecto.Changeset.put_embed(:geolocation, [%{id: "home", geohash: 623276216934563839, chronolock: 1653079771, location_description: nil}])
        |> Phos.Repo.insert()
      {:ok, index_live, _html} = live(conn, ~p"/orb")

      assert {:error, {:live_redirect, %{to: path}}} = result = index_live |> element("#homeorb-#{orb.id} a", "Edit") |> render_click()
      assert path == "/orb/#{orb.id}/edit"

      {:ok, edit_live, _html} = follow_redirect(result, conn)

      {:ok, final_live, html} =
        edit_live
        |> form("#orb-form", orb: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/orb")

      assert html =~ "Orb updated successfully"
      assert render_hook(final_live, "live_location_update", %{"longitude" => 103.96218306516853, "latitude" => 1.3395765950767413}) =~ "updated title"
    end

    test "deletes orb in listing", %{conn: conn, orb: orb, user: user} do
      {:ok, _ecto_insert} =
        %Users.Private_Profile{}
        |> Users.Private_Profile.changeset(%{user_id: user.id})
        |> Ecto.Changeset.put_embed(:geolocation, [%{id: "home", geohash: 623276216934563839, chronolock: 1653079771, location_description: nil}])
        |> Phos.Repo.insert()
      {:ok, index_live, _html} = live(conn, ~p"/orb")
      assert index_live |> element("#homeorb-#{orb.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#homeorb-#{orb.id}")
    end
  end

  describe "Show" do
    setup [:create_orb, :register_and_log_in_user]

    test "displays orb", %{conn: conn, orb: orb} do
      {:ok, _show_live, html} = live(conn, ~p"/orb/#{orb}")

      assert html =~ "Show Orb"
      assert html =~ orb.title
    end

    test "updates orb within modal", %{conn: conn, orb: orb} do
      {:ok, show_live, _html} = live(conn, ~p"/orb/#{orb.id}")

      assert {:error, {:live_redirect, %{to: path}}} = result = show_live |> element("a", "Edit") |> render_click()
      assert path == "/orb/#{orb.id}/edit"
      {:ok, edit_live, _html} = follow_redirect(result, conn)

      {:ok, _, html} =
        edit_live
        |> form("#orb-form", orb: @no_location_update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/orb")

      assert html =~ "Orb updated successfully"
      # assert html =~ "updated title"
    end
  end
end
