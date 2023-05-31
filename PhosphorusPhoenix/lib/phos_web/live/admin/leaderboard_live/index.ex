defmodule PhosWeb.Admin.LeaderboardLive.Index do
  use PhosWeb, :admin_view

  alias Phos.Repo
  alias Phos.Leaderboard

  def mount(_params, _session, socket) do
    users = Leaderboard.list_user_counts()
   {:ok, assign(socket, users: users)}
  end

  def handle_event("orb_count", _, socket) do
    users = Leaderboard.list_user_counts(:orbs)
    {:noreply, assign(socket, users: users)}
  end

  def handle_event("ally_count", unsigned_params, socket) do
    users = Leaderboard.list_user_counts(:relations)
    {:noreply, assign(socket, users: users)}
  end

  def handle_event("comment_count", unsigned_params, socket) do
    users = Leaderboard.list_user_counts(:comments)
    {:noreply, assign(socket, users: users)}
  end
end
