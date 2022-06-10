defmodule PhosWeb.OrbLiveTest do
  use PhosWeb.ConnCase
  alias PhosWeb.OrbLive.Index

  import Phoenix.LiveViewTest
  import Phos.ActionFixtures

  @create_attrs %{"title" => "some title", "active" => true, "extinguish" => %{day: 21, hour: 7, minute: 22, month: 5, year: 2022}, "initiator" => "", :location => :home, "radius" => 8, "payload" => %{"info" => "some info", "tip" => "some tip", "when" => "some when", "where" => "some where"}}
  @update_attrs %{"title" => "updated title", "active" => true, "extinguish" => %{day: 21, hour: 7, minute: 22, month: 5, year: 2022}, "initiator" => "", :location => :home, "radius" => 8, "payload" => %{"info" => "updated info", "tip" => "updated tip", "when" => "updated when", "where" => "updated where"}}
  @invalid_attrs %{"active" => true, "extinguish" => %{day: 21, hour: 7, minute: 22, month: 5, year: 2022}, "initiator" => "", :location => :home, "radius" => 8, "payload" => %{"info" => "some info", "tip" => "some tip", "when" => "some when", "where" => "some where"}}
  @no_location_update_attrs %{"title" => "updated title", "active" => true, "extinguish" => %{day: 21, hour: 7, minute: 22, month: 5, year: 2022}, "initiator" => "", "radius" => 8, "payload" => %{"info" => "updated info", "tip" => "updated tip", "when" => "updated when", "where" => "updated where"}}
  # @create_attrs %{active: true, extinguish: %{day: 21, hour: 7, minute: 22, month: 5, year: 2022}, media: true, title: "some title"}
  # @update_attrs %{active: false, extinguish: %{day: 22, hour: 7, minute: 22, month: 5, year: 2022}, media: false, title: "some updated title"}
  # @invalid_attrs %{active: false, extinguish: %{day: 30, hour: 7, minute: 22, month: 2, year: 2022}, media: false, title: nil}

  defp create_orb(_) do
    orb = orb_fixture()
    %{orb: orb}
  end

  describe "Index" do
    setup [:create_orb]

    test "lists all orbs", %{conn: conn, orb: orb} do

      {:ok, index_live, html} = live(conn, Routes.orb_index_path(conn, :index))
      assert render_hook(index_live, "live_location_update", %{"longitude" => 103.96218306516853, "latitude" => 1.3395765950767413}) =~ orb.title

    end

    test "saves new orb", %{conn: conn} do
      conn = conn
        |> assign(:geolocation, %{live: %{geohash: %{}, orbs: []}, home: %{geohash: 623276216934563839, orbs: []}})
      {:ok, index_live, _html} = live(conn, Routes.orb_index_path(conn, :index))

      assert index_live |> element("a", "New Orb") |> render_click() =~
               "New Orb"

      assert_patch(index_live, Routes.orb_index_path(conn, :new))

      {:ok, indexu_liveu, html} =
        index_live
        |> form("#orb-form", orb: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.orb_index_path(conn, :index))

      assert html =~ "Orb created successfully"
      assert render_hook(indexu_liveu, "live_location_update", %{"longitude" => 103.96218306516853, "latitude" => 1.3395765950767413}) =~ "some title"
    end

    test "updates orb in listing", %{conn: conn, orb: orb} do
      conn = conn
        |> assign(:geolocation, %{live: %{geohash: %{}, orbs: []}, home: %{geohash: 623276216934563839, orbs: []}})
      {:ok, index_live, _html} = live(conn, Routes.orb_index_path(conn, :index))

      assert index_live |> element("#homeorb-#{orb.id} a", "Edit") |> render_click() =~
               "Edit Orb"

      assert_patch(index_live, Routes.orb_index_path(conn, :edit, orb))


      {:ok, indexu_liveu, html} =
        index_live
        |> form("#orb-form", orb: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.orb_index_path(conn, :index))

      assert html =~ "Orb updated successfully"
      assert render_hook(indexu_liveu, "live_location_update", %{"longitude" => 103.96218306516853, "latitude" => 1.3395765950767413}) =~ "updated title"
    end

    test "deletes orb in listing", %{conn: conn, orb: orb} do
      conn = conn
        |> assign(:geolocation, %{live: %{geohash: %{}, orbs: []}, home: %{geohash: 623276216934563839, orbs: []}})
      {:ok, index_live, _html} = live(conn, Routes.orb_index_path(conn, :index))

      assert index_live |> element("#homeorb-#{orb.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#homeorb-#{orb.id}")
    end
  end

  describe "Show" do
    setup [:create_orb]

    test "displays orb", %{conn: conn, orb: orb} do
      {:ok, _show_live, html} = live(conn, Routes.orb_show_path(conn, :show, orb))

      assert html =~ "Show Orb"
      assert html =~ orb.title
    end

    test "updates orb within modal", %{conn: conn, orb: orb} do
      {:ok, show_live, _html} = live(conn, Routes.orb_show_path(conn, :show, orb))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Orb"

      assert_patch(show_live, Routes.orb_show_path(conn, :edit, orb))


      # assert show_live
      #        |> form("#orb-form", orb: @invalid_attrs)
      #        |> render_change() =~ "is invalid"

      {:ok, _, html} =
        show_live
        |> form("#orb-form", orb: @no_location_update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.orb_show_path(conn, :show, orb))

      assert html =~ "Orb updated successfully"
      assert html =~ "updated title"
    end
  end
end
