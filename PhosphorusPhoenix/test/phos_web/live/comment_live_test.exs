defmodule PhosWeb.CommentLiveTest do
  use PhosWeb.ConnCase
  import Phoenix.LiveViewTest
  import Phos.ActionFixtures
  # import PhosWeb.ConnCase

  alias Phos.Comments
  alias Phos.CommentsFixtures

  @create_attrs %{body: "some body"}
  @update_attrs %{body: "some updated body"}
  @invalid_attrs %{body: nil}
  @reply_attrs %{body: "some reply body"}

  defp create_orb(_) do
    orb = orb_fixture()
    %{orb: orb}
  end

  describe "Show" do
    setup [:create_orb, :register_and_log_in_user]

    test "lists root comments", %{conn: conn, orb: orb, user: user} do
      CommentsFixtures.comment_fixture(%{orb_id: orb.id, initiator_id: user.id})

      {:ok, index_live, _html} = live(conn, ~p"/orb/#{orb.id}")

      assert render(index_live) =~ "some body"
    end

    test "create new comment", %{conn: conn, orb: orb} do
      {:ok, index_live, _html} = live(conn, ~p"/orb/#{orb.id}")

      index_live
      |> form("#create-root-comment-#{orb.id}", comment: @create_attrs)
      |> render_submit()

      comment = Comments.get_root_comments_by_orb(orb.id) |> List.last()

      send(index_live.pid, {:new_comment, comment})
      view = render(index_live)

      assert view =~ "Comment added successfully"
      assert view =~ "some body"

      on_exit(fn -> :timer.sleep(100) end)
    end

    test "create invalid comment", %{conn: conn, orb: orb} do
      {:ok, index_live, _html} = live(conn, ~p"/orb/#{orb.id}")

      view =
        index_live
        |> form("#create-root-comment-#{orb.id}", comment: @invalid_attrs)
        |> render_submit()

      assert view =~ "placeholder-rose-300"
    end

    test "edit comment", %{conn: conn, orb: orb, user: user} do
      comment = CommentsFixtures.comment_fixture(%{orb_id: orb.id, initiator_id: user.id})

      {:ok, index_live, _html} = live(conn, ~p"/orb/#{orb.id}")
      assert index_live |> element("#comment-#{comment.id} a", "Edit") |> render_click() =~
               "Edit"

      index_live
      |> form("#edit-comment-#{comment.id}", comment: @update_attrs)
      |> render_submit()

      send(index_live.pid, {:edit_comment, comment})

      assert render(index_live) =~ "Comment updated successfully"
    end

    test "deactivate comment", %{conn: conn, orb: orb, user: user} do
      comment = CommentsFixtures.comment_fixture(%{orb_id: orb.id, initiator_id: user.id})

      {:ok, index_live, _html} = live(conn, ~p"/orb/#{orb.id}")
      assert index_live |> element("#comment-#{comment.id} a", "Delete") |> render_click()

      refute has_element?(index_live, "#comment-#{comment.id} a", "Edit")
      refute has_element?(index_live, "#comment-#{comment.id} a", "Delete")
    end

    test "reply to existing comment", %{conn: conn, orb: orb, user: user} do
      comment = CommentsFixtures.comment_fixture(%{orb_id: orb.id, initiator_id: user.id})

      {:ok, index_live, _html} = live(conn, ~p"/orb/#{orb.id}")
      assert index_live |> element("#comment-#{comment.id} a", "reply") |> render_click() =~
      "reply"

      index_live
      |> form("#create-child-comment-#{comment.id}", comment: @reply_attrs)
      |> render_submit()

      child_comment = Comments.get_descendents_comment(comment.id) |> List.last()

      send(index_live.pid, {:child_comment, child_comment})

      assert render(index_live) =~ "Reply added successfully"

      on_exit(fn -> :timer.sleep(100) end)
    end

    test "lists ancestor comments", %{conn: conn, orb: orb, user: user} do
      root_comment = CommentsFixtures.comment_fixture(%{orb_id: orb.id, body: "root_comment", initiator_id: user.id})
      second_level_comment = CommentsFixtures.comment_fixture(%{orb_id: orb.id, body: "second_level_comment", initiator_id: user.id, parent_id: root_comment.id, parent_path: to_string(root_comment.path)})

      {:ok, index_live, html} = live(conn, ~p"/orb/#{orb.id}")

      assert html =~ root_comment.body

      new_html = index_live |> element("#initshowreply-#{root_comment.id} a", "View replies[1]") |> render_click()
      assert new_html =~ second_level_comment.body
    end
  end
end
