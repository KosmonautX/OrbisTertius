defmodule PhosWeb.MemoryLiveTest do
  use PhosWeb.ConnCase

  import Phoenix.LiveViewTest
  import Phos.MessageFixtures

  @create_attrs %{media: true, message: "some message"}
  @update_attrs %{media: false, message: "some updated message"}
  @invalid_attrs %{media: false, message: nil}

  defp create_memory(_) do
    memory = memory_fixture()
    %{memory: memory}
  end

  # describe "Index" do
  #   setup [:create_memory, :register_and_log_in_user]

  #   test "lists all memories", %{conn: conn, memory: memory} do
  #     {:ok, _index_live, html} = live(conn, ~p"/memories")

  #     assert html =~ "Listing Memories"
  #     assert html =~ memory.message
  #   end

  #   test "saves new memory", %{conn: conn} do
  #     {:ok, index_live, _html} = live(conn, ~p"/memories")

  #     assert index_live |> element("a", "New Memory") |> render_click() =~
  #              "New Memory"

  #     assert_patch(index_live, ~p"/memories/new")

  #     assert index_live
  #            |> form("#memory-form", memory: @invalid_attrs)
  #            |> render_change() =~ "can&#39;t be blank"

  #     {:ok, _, html} =
  #       index_live
  #       |> form("#memory-form", memory: @create_attrs)
  #       |> render_submit()
  #       |> follow_redirect(conn, ~p"/memories")

  #     assert html =~ "Memory created successfully"
  #     assert html =~ "some message"
  #   end

  #   test "updates memory in listing", %{conn: conn, memory: memory} do
  #     {:ok, index_live, _html} = live(conn, ~p"/memories")

  #     assert index_live |> element("#memories-#{memory.id} a", "Edit") |> render_click() =~
  #              "Edit Memory"

  #     assert_patch(index_live, ~p"/memories/#{memory}/edit")

  #     assert index_live
  #            |> form("#memory-form", memory: @invalid_attrs)
  #            |> render_change() =~ "can&#39;t be blank"

  #     {:ok, _, html} =
  #       index_live
  #       |> form("#memory-form", memory: @update_attrs)
  #       |> render_submit()
  #       |> follow_redirect(conn, ~p"/memories")

  #     assert html =~ "Memory updated successfully"
  #     assert html =~ "some updated message"
  #   end

  #   test "deletes memory in listing", %{conn: conn, memory: memory} do
  #     {:ok, index_live, _html} = live(conn, ~p"/memories")

  #     assert index_live |> element("#memories-#{memory.id} a", "Delete") |> render_click()
  #     refute has_element?(index_live, "#memory-#{memory.id}")
  #   end
  # end

  # describe "Show" do
  #   setup [:create_memory, :register_and_log_in_user]

  #   test "displays memory", %{conn: conn, memory: memory} do
  #     {:ok, _show_live, html} = live(conn, ~p"/memories/#{memory}")

  #     assert html =~ "Show Memory"
  #     assert html =~ memory.message
  #   end

  #   test "updates memory within modal", %{conn: conn, memory: memory} do
  #     {:ok, show_live, _html} = live(conn, ~p"/memories/#{memory}")

  #     assert show_live |> element("a", "Edit") |> render_click() =~
  #              "Edit Memory"

  #     assert_patch(show_live, ~p"/memories/#{memory}/show/edit")

  #     assert show_live
  #            |> form("#memory-form", memory: @invalid_attrs)
  #            |> render_change() =~ "can&#39;t be blank"

  #     {:ok, _, html} =
  #       show_live
  #       |> form("#memory-form", memory: @update_attrs)
  #       |> render_submit()
  #       |> follow_redirect(conn, ~p"/memories/#{memory}")

  #     assert html =~ "Memory updated successfully"
  #     assert html =~ "some updated message"
  #   end
  # end
end
