defmodule PhosWeb.Admin.LeaderboardLive.Index do
  use PhosWeb, :admin_view

  alias Phos.Repo
  alias Phos.Leaderboard
  alias Phos.Action.Orb


  def mount(_params, _session, socket) do
    limit = 10
    page = 1
    %{data: users, meta: meta} = Leaderboard.list_user_counts(limit, page, :orbs)
    %{data: orbs} = Leaderboard.rank_orbs(limit, page)

   {:ok,
    socket
    |> assign(users: users)
    |> assign(orb_view: false)
    |> assign(orbs: orbs)
    |> assign(limit: limit)
    |> assign(current: page)
    |> assign(pagination: meta.pagination)
  }
  end

  def handle_params(
    %{"page" => page},
    _url,
    %{assigns: %{limit: limit}} = socket)
    do

    expected_page = parse_integer(page)
    %{data: users, meta: meta} = Leaderboard.list_user_counts(limit, expected_page, :orbs)

    {:noreply,
      socket
      |> assign(users: users)
      |> assign(current: expected_page)
      |> assign(pagination: meta.pagination)
    }
  end

  def handle_params(%{"filter_by" => option}, _url, %{assigns: %{limit: limit, pagination: pagination}} = socket) do

    case option do
      "orbs" ->
        Leaderboard.list_user_counts(limit, pagination.current, :orbs)
      "allies" ->
        Leaderboard.list_user_counts(limit, pagination.current, :relations)
      "comments" ->
        Leaderboard.list_user_counts(limit, pagination.current, :comments)
      "chats" ->
        Leaderboard.list_user_counts(limit, pagination.current, :chats)
    end
    {:noreply, socket}
  end

  def handle_params(_params, _url, socket), do: {:noreply, socket}

  def handle_event("filter", %{"filter_by" => option}, %{assigns: %{limit: limit, pagination: pagination}} = socket) do
    %{data: users, meta: meta} =
      case option do
        "orbs" ->
          Leaderboard.list_user_counts(limit, pagination.current, :orbs)
        "allies" ->
          Leaderboard.list_user_counts(limit, pagination.current, :relations)
        "comments" ->
          Leaderboard.list_user_counts(limit, pagination.current, :comments)
        "chats" ->
          Leaderboard.list_user_counts(limit, pagination.current, :chats)
      end

    {:noreply,
    socket
    |> assign(users: users)
    |> assign(orb_view: false)
    }
  end
  # def handle_event("orb_count", _, %{assigns: %{limit: limit}} = socket) do
  #   %{data: users} = Leaderboard.list_user_counts(limit, 1, :orbs)
  #   {:noreply,
  #   socket

  #   |> assign(orb_view: false)
  # }
  # end

  # def handle_event("ally_count", _, %{assigns: %{pagination: pagination, limit: limit}} = socket) do
  #   %{data: users} = Leaderboard.list_user_counts(limit, 1, :relations)
  #   {:noreply,
  #   socket
  #   |> assign(users: users)
  #   |> assign(orb_view: false)
  #   |> assign(pagination: pagination)
  #   |> assign(current: 1)
  # }
  # end

  # def handle_event("comment_count", _, %{assigns: %{pagination: pagination, limit: limit}} = socket) do
  #   %{data: users} = Leaderboard.list_user_counts(limit, 1, :comments)
  #   {:noreply,
  #   socket
  #   |> assign(users: users)
  #   |> assign(orb_view: false)
  #   |> assign(pagination: pagination)
  #   |> assign(current: 1)
  # }  end

  # def handle_event("chat_count", _, %{assigns: %{pagination: pagination, limit: limit}} = socket) do
  #   %{data: users} = Leaderboard.list_user_counts(limit, 1, :chats)
  #   {:noreply,
  #   socket
  #   |> assign(users: users)
  #   |> assign(orb_view: false)
  #   |> assign(pagination: pagination)
  #   |> assign(current: 1)
  # }  end

  def handle_event("orb_rank", _, socket) do
    {:noreply,
    socket
    |> assign(orb_view: true)
    }
  end

  defp parse_integer(text) do
    try do
      String.to_integer(text)
    rescue
      ArgumentError -> 1
    end
  end

end
