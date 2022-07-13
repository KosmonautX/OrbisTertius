defmodule PhosWeb.CommentControllerTest do
  use PhosWeb.ConnCase

  import Phos.CommentsFixtures
  import Phos.ActionFixtures

  alias Phos.Comments.Comment

  @create_root_attrs %{
    body: "some root",
    orb_id: "7488a646-e31f-11e4-aace-600308960662"
  }

  @create__child_attrs %{
    body: "some child",
    parent_id: "7488a646-e31f-11e4-aace-600308960662"
  }

  @update_attrs %{
    body: "some updated body",
    parent_id: "7488a646-e31f-11e4-aace-600308960668"
  }
  @invalid_attrs %{body: nil, parent_id: nil}

  defp create_orb(_) do
    orb = orb_fixture()
    %{orb: orb}
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    setup [:create_orb, :register_and_log_in_user]

    test "lists all comments", %{conn: conn, orb: orb, user: user} do
      comment = comment_fixture(%{orb_id: orb.id, initiator_id: user.id})
      conn = get(conn, Routes.comment_path(conn, :index))
      assert json_response(conn, 200)["data"] =~ comment.body
    end
  end

  describe "create comment" do
    test "renders comment when data is valid", %{conn: conn} do
      conn = post(conn, Routes.comment_path(conn, :create), comment: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.comment_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "active" => true,
               "body" => "some body",
               "parent_id" => "7488a646-e31f-11e4-aace-600308960662"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.comment_path(conn, :create), comment: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update comment" do
    setup [:create_comment]

    test "renders comment when data is valid", %{conn: conn, comment: %Comment{id: id} = comment} do
      conn = put(conn, Routes.comment_path(conn, :update, comment), comment: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.comment_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "active" => false,
               "body" => "some updated body",
               "parent_id" => "7488a646-e31f-11e4-aace-600308960668"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, comment: comment} do
      conn = put(conn, Routes.comment_path(conn, :update, comment), comment: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete comment" do
    setup [:create_comment]

    test "deletes chosen comment", %{conn: conn, comment: comment} do
      conn = delete(conn, Routes.comment_path(conn, :delete, comment))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.comment_path(conn, :show, comment))
      end
    end
  end

  defp create_comment(_) do
    comment = comment_fixture()
    %{comment: comment}
  end
end
