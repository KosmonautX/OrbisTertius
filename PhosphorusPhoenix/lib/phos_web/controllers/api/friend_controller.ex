defmodule PhosWeb.API.FriendController do
  use PhosWeb, :controller

  action_fallback PhosWeb.API.FallbackController

  alias Phos.Users.{RelationRoot}
  alias Phos.Folk

  def index(%{assigns: %{current_user: user}} = conn, %{"page" => page}) do
    friends = Folk.friends(user.id, page)
    render(conn, "paginated.json",
      relations: friends.data
      |> Enum.map(fn branch -> branch.root end)
      |> self_initiated_enricher(user.id),
      meta: friends.meta
    )
  end

  def show_others(%{assigns: %{current_user: _user}} = conn, %{"id" => user_id, "page" => page}) do
    friends = Folk.friends(user_id, page)
    render(conn, "paginated.json",
      relations: friends.data
      |> Enum.map(fn branch -> branch.root end)
      |> self_initiated_enricher(user_id),
      meta: friends.meta
    )
  end

  def create(%{assigns: %{current_user: user}} = conn, %{"acceptor_id" => acceptor_id}) do
    with {:ok, %RelationRoot{} = relation} <- Folk.add_friend(user.id, acceptor_id) do
      conn
      |> put_status(:created)
      |> render("show.json", relation: relation)
    end
  end

  def delete(%{assigns: %{current_user: user}} = conn, %{"id" => rel_id}) do
    root = Folk.get_relation!(rel_id)
    with true <- (root.acceptor_id == user.id) or (root.initiator_id == user.id),
    {:ok, %RelationRoot{} = relation} <- Folk.delete_relation(root) do
      conn
      |> put_status(200)
      |> render("show.json", relation: relation)
    else
      false -> {:error, :unauthorized}
    end
  end

  def requests(%{assigns: %{current_user: user}} = conn, %{"page" => page}) do
    requested_friends = Folk.friend_requests(user.id, page)
    render(conn, "paginated.json", relations: requested_friends.data |> self_initiated_enricher(user.id),
      meta: requested_friends.meta )
  end

  def pending(%{assigns: %{current_user: user}} = conn, %{"page" => page}) do
    requested_friends = Folk.pending_requests(user.id, page)
    render(conn, "paginated.json", relations: requested_friends.data |> self_initiated_enricher(user.id),
      meta: requested_friends.meta )
  end

  defp self_initiated_enricher(relations, user_id) when is_list(relations) do
    relations
    |> Enum.map(fn relation -> %{relation | self_initiated: user_id == relation.initiator_id} end)
  end

  def ended(%{assigns: %{current_user: user}} = conn, %{"relation_id" => rel_id}) do
    root = Folk.get_relation!(rel_id)
    with true <- root.acceptor_id == user.id,
    {:ok, %RelationRoot{} = relation} <- Folk.update_relation(root, %{"state" => "ghosted"}) do
      conn
      |> put_status(200)
      |> render("show.json", relation: relation)
    else
      false -> {:error, :unauthorized}
    end
  end

  def begun(%{assigns: %{current_user: user}} = conn, %{"relation_id" => rel_id}) do
    root = Folk.get_relation!(rel_id)
    with true <- root.acceptor_id == user.id,
    {:ok, %RelationRoot{} = relation} <- Folk.update_relation(root, %{"state" => "completed"}) do
      conn
      |> put_status(200)
      |> render("show.json", relation: relation)
    else
      false -> {:error, :unauthorized}
    end
  end

  def show_discovery(%{assigns: %{current_user: user}} = conn, %{"id" => hashes, "page" => page}) do
    geohashes = String.split(hashes, ",")
    |> Enum.map(fn hash -> String.to_integer(hash) |> :h3.parent(8) end)
    |> Enum.uniq()
    live_friends = Phos.Action.users_by_geohashes({geohashes, user.id}, page)
    render(conn, "paginated.json", friends: live_friends)
  end

  def show_discovery(%{assigns: %{current_user: user}} = conn, %{"id" => hashes}) do
    geohashes = String.split(hashes, ",")
    |> Enum.map(fn hash -> String.to_integer(hash) |> :h3.parent(8) end)
    |> Enum.uniq()
    live_friends = Phos.Action.users_by_geohashes({geohashes, user.id}, 1)
    render(conn, "paginated.json", friends: live_friends)
  end
 end
