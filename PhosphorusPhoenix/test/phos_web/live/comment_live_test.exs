defmodule PhosWeb.CommentLiveTest do
  use PhosWeb.ConnCase
  import Phoenix.LiveViewTest
  import Phos.ActionFixtures
  # import PhosWeb.ConnCase

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

      view =
        index_live
        |> form("#comment-form", comment: @create_attrs)
        |> render_submit()

      assert view =~ "Comment added successfully"
      assert view =~ "some body"
    end

    test "create invalid comment", %{conn: conn, orb: orb} do

      {:ok, index_live, _html} = live(conn, ~p"/orb/#{orb.id}")

      view =
        index_live
        |> form("#comment-form", comment: @invalid_attrs)
        |> render_submit()

      assert view =~ "can&#39;t be blank"
    end

    test "edit comment", %{conn: conn, orb: orb, user: user} do
      comment = CommentsFixtures.comment_fixture(%{orb_id: orb.id, initiator_id: user.id})

      {:ok, index_live, _html} = live(conn, ~p"/orb/#{orb.id}")
      assert index_live |> element("#comment-#{comment.id} a", "Edit") |> render_click() =~
               "Edit"

      assert_patch(index_live, ~p"/orb/#{orb.id}/edit/#{comment.id}")

      view =
        index_live
        |> form("#comment-replyedit-form", comment: @update_attrs)
        |> render_submit()

      assert view =~ "Comment updated successfully"
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
      assert index_live |> element("#comment-#{comment.id} a", "Reply") |> render_click() =~
      "reply"

      view =
        index_live
        |> form("#comment-replyedit-form", comment: @reply_attrs)
        |> render_submit()

      assert view =~ "Reply added successfully"
      assert view =~ "some reply body"
    end

    test "lists ancestor comments", %{conn: conn, orb: orb, user: user} do
      root_comment = CommentsFixtures.comment_fixture(%{orb_id: orb.id, body: "root_comment", initiator_id: user.id})
      second_level_comment = CommentsFixtures.comment_fixture(%{orb_id: orb.id, body: "second_level_comment", initiator_id: user.id, parent_id: root_comment.id, parent_path: to_string(root_comment.path)})

      {:ok, index_live, html} = live(conn, ~p"/orb/#{orb.id}")

      assert html =~ root_comment.body

      new_html = index_live |> element("#initshowreply-#{root_comment.id} a", "Show replies [1]") |> render_click()
      assert new_html =~ second_level_comment.body
    end
  end
end
