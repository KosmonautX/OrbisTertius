defmodule PhosWeb.CommentLiveTest do
  use PhosWeb.ConnCase
  alias PhosWeb.CommentLive.Index
  alias Phos.Users
  alias Phos.Comments
  import Phoenix.LiveViewTest
  import Phos.ActionFixtures
  # import PhosWeb.ConnCase
  import Phos.UsersFixtures
  import Phos.CommentsFixtures

  @create_attrs %{body: "some body"}
  @update_attrs %{body: "some updated body"}
  @reply_attrs %{body: "some reply body"}

  defp create_comment(_) do
    comment = comment_fixture()
    %{comment: comment}
  end

  defp create_orb(_) do
    orb = orb_fixture()
    %{orb: orb}
  end

  describe "Show" do
    setup [:create_orb, :register_and_log_in_user]

    test "lists root comments", %{conn: conn, orb: orb, user: user} do
      Phos.CommentsFixtures.comment_fixture(%{orb_id: orb.id, initiator_id: user.id})

      {:ok, index_live, html} = live(conn, Routes.orb_show_path(conn, :show, orb))

      assert render(index_live) =~ "some body"

    end


    test "create new comment", %{conn: conn, orb: orb} do

      {:ok, index_live, _html} = live(conn, Routes.orb_show_path(conn, :show, orb))

      view =
        index_live
        |> form("#comment-form", comment: @create_attrs)
        |> render_submit()

      assert view =~ "Comment added successfully"
      assert view =~ "some body"
    end

    test "edit comment", %{conn: conn, orb: orb, user: user} do
      comment = Phos.CommentsFixtures.comment_fixture(%{orb_id: orb.id, initiator_id: user.id})

      {:ok, index_live, _html} = live(conn, Routes.orb_show_path(conn, :show, orb))
      assert index_live |> element("#comment-#{comment.id} a", "Edit") |> render_click() =~
               "Edit"

      assert_patch(index_live, Routes.orb_show_path(conn, :edit_comment, orb, comment))

      view =
        index_live
        |> form("#comment-replyedit-form", comment: @update_attrs)
        |> render_submit()

      assert view =~ "Comment updated successfully"
    end

    test "deactivate comment", %{conn: conn, orb: orb, user: user} do
      comment = Phos.CommentsFixtures.comment_fixture(%{orb_id: orb.id, initiator_id: user.id})

      {:ok, index_live, _html} = live(conn, Routes.orb_show_path(conn, :show, orb))
      assert index_live |> element("#comment-#{comment.id} a", "Delete") |> render_click()

      refute has_element?(index_live, "#comment-#{comment.id} a", "Edit")
      refute has_element?(index_live, "#comment-#{comment.id} a", "Delete")
    end

    test "reply to existing comment", %{conn: conn, orb: orb, user: user} do
      comment = Phos.CommentsFixtures.comment_fixture(%{orb_id: orb.id, initiator_id: user.id})

      {:ok, index_live, _html} = live(conn, Routes.orb_show_path(conn, :show, orb))
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
      root_comment = Phos.CommentsFixtures.comment_fixture(%{orb_id: orb.id, body: "root_comment", initiator_id: user.id})
      second_level_comment = Phos.CommentsFixtures.comment_fixture(%{orb_id: orb.id, body: "second_level_comment", initiator_id: user.id, parent_id: root_comment.id, parent_path: to_string(root_comment.path)})
      third_level_comment = Phos.CommentsFixtures.comment_fixture(%{orb_id: orb.id, body: "third_level_comment", initiator_id: user.id, parent_id: second_level_comment.id, parent_path: to_string(second_level_comment.path)})

      {:ok, index_live, html} = live(conn, Routes.orb_show_path(conn, :show_ancestor, orb.id, third_level_comment))

      assert html =~ root_comment.body
      assert html =~ second_level_comment.body
      assert html =~ third_level_comment.body
    end
  end
end
