defmodule PhosWeb.API.FriendController do
  use PhosWeb, :controller

  action_fallback PhosWeb.API.FallbackController

  def index(%{assigns: %{current_user: user}} = conn, _params) do
    friends = Phos.Users.friends(user)
    render(conn, "index.json", friends: friends)
  end

  def requests(%{assigns: %{current_user: user}} = conn, _params) do
    requested_friends = Phos.Users.friend_requests(user)
    render(conn, "index.json", friends: requested_friends)
  end

  def pending(%{assigns: %{current_user: user}} = conn, _params) do
    requested_friends = Phos.Users.pending_requests(user)
    render(conn, "index.json", friends: requested_friends)
  end

  def create(%{assigns: %{current_user: user}} = conn, %{"friend_id" => acceptor_id}) do
    case Phos.Users.add_friend(user.id, acceptor_id) do
      {:ok, relation} -> render(conn, "relation.json", relation: relation)
      {:error, reason} -> render(conn |> put_status(:conflict), "relation_error.json", reason: reason)
    end
  end

  def ended(%{assigns: %{current_user: user}} = conn, %{"friend_id" => user_id}) do
    case Phos.Users.reject_friend(user.id, user_id) do
      {:ok, relation} -> render(conn, "relation.json", relation: relation)
      {:error, reason} -> render(conn |> put_status(:conflict), "relation_error.json", reason: reason)
    end
  end

  def begun(%{assigns: %{current_user: user}} = conn, %{"friend_id" => user_id}) do
    case Phos.Users.accept_friend(user.id, user_id) do
      {:ok, relation} -> render(conn, "relation.json", relation: relation)
      {:error, reason} -> render(conn |> put_status(:conflict), "relation_error.json", reason: reason)
    end
  end

  def show_discovery(conn, %{"id" => hash, "page" => page}) do
    live_friends = Phos.Action.users_by_geohashes([String.to_integer(hash) |> :h3.parent(8)], page)
    render(conn, "paginated.json", friends: live_friends)
  end

  def show_discovery(conn, %{"id" => hash}) do
    live_friends = Phos.Action.users_by_geohashes([String.to_integer(hash) |> :h3.parent(8)], 1)
    render(conn, "paginated.json", friends: live_friends)
  end
end
