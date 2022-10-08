defmodule PhosWeb.CommentControllerTest do
  use PhosWeb.ConnCase

  import Phos.CommentsFixtures
  import Phos.ActionFixtures

  alias Phos.Comments.Comment

  @create_root_attrs %{
    body: "some root",
    orb_id: "6304af82-088c-4383-ae23-e70ca7d9460d",
    initiator_id: "a45bbc2c-22b8-42ca-9c11-77bf609e2d86",
  }

  @create__child_attrs %{
    body: "some child",
    parent_id: "7488a646-e31f-11e4-aace-600308960662"
  }

  @update_attrs %{
    body: "some updated body",
    parent_id: "7488a646-e31f-11e4-aace-600308960668"
  }
  @invalid_attrs %{
    body: nil,
    orb_id: "7488a646-e31f-11e4-aace-600308960662"
  }

  defp create_orb(_) do
    orb = orb_fixture()
    %{orb: orb}
  end

  setup %{conn: conn} do
    {:ok, conn: conn
    |> put_req_header("accept", "application/json")}
  end

  describe "comments index" do
    setup [:create_orb, :inject_user_token]

    test "lists all comments", %{conn: conn, orb: orb, user: user} do
      comment = comment_fixture(%{orb_id: orb.id, initiator_id: user.id})
      conn = get(conn, Routes.comment_path(conn, :index))

      assert [%{"id" => id}] = json_response(conn, 200)["data"]

      assert [%{
        "id" => ^id,
        "active" => true,
        "body" => "some body",
      }] = json_response(conn, 200)["data"]
    end

    test "lists root comments of orb", %{conn: conn, orb: orb, user: user} do
      root_comment = comment_fixture(%{orb_id: orb.id, body: "root_comment", initiator_id: user.id})
      root_comment2 = comment_fixture(%{orb_id: orb.id, body: "root_comment_2", initiator_id: user.id})

      conn = get(conn, Routes.comment_path(conn, :show_root, orb))

      assert [%{
        "body" => "root_comment",
        }, %{
        "body" => "root_comment_2",
      }] = json_response(conn, 200)["data"]
    end

    test "lists ancestors of comment", %{conn: conn, orb: orb, user: user} do
      root_comment = comment_fixture(%{orb_id: orb.id, body: "root_comment", initiator_id: user.id})
      second_level_comment = comment_fixture(%{orb_id: orb.id, body: "second_level_comment", initiator_id: user.id, parent_id: root_comment.id, parent_path: to_string(root_comment.path)})
      third_level_comment = comment_fixture(%{orb_id: orb.id, body: "third_level_comment", initiator_id: user.id, parent_id: second_level_comment.id, parent_path: to_string(second_level_comment.path)})

      conn = get(conn, Routes.comment_path(conn, :show_ancestor, third_level_comment))

      assert [%{
        "body" => "root_comment",
        }, %{
        "body" => "second_level_comment",
        }, %{
          "body" => "third_level_comment",
        }] = json_response(conn, 200)["data"]
    end
  end

  describe "create comment" do
    setup [:create_orb, :inject_user_token]
    test "renders comment when data is valid", %{conn: conn, orb: orb, user: user} do
      comment = %{
        body: "some root",
        orb_id: orb.id,
        initiator_id: user.id,
      }

      conn = post(conn, Routes.comment_path(conn, :create), comment)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.comment_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "active" => true,
               "body" => "some root",
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.comment_path(conn, :create), @invalid_attrs)

      assert %{
        "body" => ["can't be blank"],
      } = json_response(conn, 422)["errors"]
    end
  end

  describe "create child comment" do
    setup [:create_orb, :inject_user_token]
    test "renders comment when data is valid", %{conn: conn, orb: orb, user: user} do
      %{id: parent_comment_id} = comment = comment_fixture(%{orb_id: orb.id, initiator_id: user.id})

      child_comment = %{
        body: "some child",
        initiator_id: user.id,
        parent_id: parent_comment_id
      }

      conn = post(conn, Routes.comment_path(conn, :create), child_comment)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.comment_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "active" => true,
               "body" => "some child",
               "parent_id" => parent_comment_id
             } = json_response(conn, 200)["data"]
    end

    test "renders comment when data is invalid", %{conn: conn, orb: orb, user: user} do
      %{id: parent_comment_id} = comment = comment_fixture(%{orb_id: orb.id, initiator_id: user.id})

      child_comment = %{
        body: "",
        initiator_id: user.id,
        parent_id: parent_comment_id
      }

      conn = post(conn, Routes.comment_path(conn, :create), child_comment)

      assert %{
        "body" => ["can't be blank"],
      } = json_response(conn, 422)["errors"]
    end
  end

  describe "update comment" do
    setup [:create_orb, :inject_user_token]

    test "renders comment when data is valid", %{conn: conn, orb: orb, user: user} do
      comment = comment_fixture(%{orb_id: orb.id, initiator_id: user.id})
      conn = put(conn, Routes.comment_path(conn, :update, comment), @update_attrs)
      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.comment_path(conn, :show, id))

      assert %{
        "id" => ^id,
        "active" => true,
        "body" => "some updated body"
      } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, orb: orb, user: user} do
      comment = comment_fixture(%{orb_id: orb.id, initiator_id: user.id})
      conn = put(conn, Routes.comment_path(conn, :update, comment), @invalid_attrs)

      assert %{
        "body" => ["can't be blank"],
      } = json_response(conn, 422)["errors"]
    end
  end

  describe "update child comment" do
    setup [:create_orb, :inject_user_token]

    test "renders comment when data is valid", %{conn: conn, orb: orb, user: user} do
      root_comment = comment_fixture(%{orb_id: orb.id, initiator_id: user.id})
      second_level_comment = comment_fixture(%{orb_id: orb.id, initiator_id: user.id, parent_id: root_comment.id})

      conn = put(conn, Routes.comment_path(conn, :update, second_level_comment), @update_attrs)
      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.comment_path(conn, :show, id))

      assert %{
        "id" => ^id,
        "active" => true,
        "body" => "some updated body"
      } = json_response(conn, 200)["data"]
    end

    test "renders comment when data is invalid", %{conn: conn, orb: orb, user: user} do
      root_comment = comment_fixture(%{orb_id: orb.id, initiator_id: user.id})
      second_level_comment = comment_fixture(%{orb_id: orb.id, initiator_id: user.id, parent_id: root_comment.id})

      conn = put(conn, Routes.comment_path(conn, :update, second_level_comment), @invalid_attrs)

      assert %{
        "body" => ["can't be blank"],
      } = json_response(conn, 422)["errors"]
    end
  end

  describe "delete comment" do
    setup [:create_orb, :inject_user_token]

    test "deletes chosen comment", %{conn: conn, orb: orb, user: user} do
      comment = comment_fixture(%{orb_id: orb.id, initiator_id: user.id})
      conn = delete(conn, Routes.comment_path(conn, :delete, comment))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.comment_path(conn, :show, comment))
      end
    end
  end
end
