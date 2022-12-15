defmodule PhosWeb.ReverieLiveTest do
  use PhosWeb.ConnCase

  import Phoenix.LiveViewTest
  import Phos.MessageFixtures

  @create_attrs %{read: "2022-12-14T19:43:00Z"}
  @update_attrs %{read: "2022-12-15T19:43:00Z"}
  @invalid_attrs %{read: nil}

  defp create_reverie(_) do
    reverie = reverie_fixture()
    %{reverie: reverie}
  end

  describe "Index" do
    setup [:create_reverie, :register_and_log_in_user]

    test "lists all reveries", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/reveries")

      assert html =~ "Listing Reveries"
    end

    test "saves new reverie", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/reveries")

      assert index_live |> element("a", "New Reverie") |> render_click() =~
               "New Reverie"

      assert_patch(index_live, ~p"/reveries/new")

      assert index_live
             |> form("#reverie-form", reverie: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#reverie-form", reverie: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/reveries")

      assert html =~ "Reverie created successfully"
    end

    test "updates reverie in listing", %{conn: conn, reverie: reverie} do
      {:ok, index_live, _html} = live(conn, ~p"/reveries")

      assert index_live |> element("#reveries-#{reverie.id} a", "Edit") |> render_click() =~
               "Edit Reverie"

      assert_patch(index_live, ~p"/reveries/#{reverie}/edit")

      assert index_live
             |> form("#reverie-form", reverie: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#reverie-form", reverie: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/reveries")

      assert html =~ "Reverie updated successfully"
    end

    test "deletes reverie in listing", %{conn: conn, reverie: reverie} do
      {:ok, index_live, _html} = live(conn, ~p"/reveries")

      assert index_live |> element("#reveries-#{reverie.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#reverie-#{reverie.id}")
    end
  end

  describe "Show" do
    setup [:create_reverie, :register_and_log_in_user]

    test "displays reverie", %{conn: conn, reverie: reverie} do
      {:ok, _show_live, html} = live(conn, ~p"/reveries/#{reverie}")

      assert html =~ "Show Reverie"
    end

    test "updates reverie within modal", %{conn: conn, reverie: reverie} do
      {:ok, show_live, _html} = live(conn, ~p"/reveries/#{reverie}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Reverie"

      assert_patch(show_live, ~p"/reveries/#{reverie}/show/edit")

      assert show_live
             |> form("#reverie-form", reverie: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#reverie-form", reverie: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/reveries/#{reverie}")

      assert html =~ "Reverie updated successfully"
    end
  end
end
