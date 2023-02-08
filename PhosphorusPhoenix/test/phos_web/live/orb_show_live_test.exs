defmodule PhosWeb.OrbShowLiveTest do
  use PhosWeb.ConnCase
  import Phoenix.LiveViewTest
  import Phos.ActionFixtures

  defp create_orb(_) do
    orb = orb_fixture()
    %{orb: orb}
  end

  defp create_orb_no_loc(_) do
    orb = orb_fixture_no_location()
    %{orb: orb}
  end

  describe "testing show orb with location" do
    setup [:create_orb, :register_and_log_in_user]

    test "show_orb_profile", %{conn: conn, orb: orb} do
      {:ok, _show_live, html} = live(conn, ~p"/orb/#{orb.id}")
      assert html =~ orb.initiator.username
      assert html =~ orb.payload.where
      assert html =~ orb.title
      assert html =~ "Comments"
      assert html =~ orb.inserted_at

      assert html =~
               Phos.Orbject.S3.get!("ORB", orb.id, "public/banner") |> String.split("?") |> hd()
    end

    # test "Copyclip", %{conn: conn, orb: orb} do
    #   {:ok, view, _html} = live(conn, ~p"/orb/#{orb.id}")

    #   assert view
    #          |> element("#scry_orb-#{orb.id}-sharebtn")
    #          |> render_click() =~ "Copy link to Scratchbac"
    # end
  end

  describe "testing show orb without location" do
    setup [:create_orb_no_loc, :register_and_log_in_user]

    test "without_orb_location", %{conn: conn, orb: orb} do
      {:ok, _show_live, html} = live(conn, ~p"/orb/#{orb.id}")

      assert html =~ "Somewhere"
    end
  end
end
