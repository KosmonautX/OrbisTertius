defmodule PhosWeb.Admin.LeaderboardLive.Index do
  use PhosWeb, :admin_view

  alias Phos.Repo
  alias Phos.Leaderboard
  alias Phos.Action.Orb


  def mount(_params, _session, socket) do
    users = Leaderboard.list_user_counts(:orbs)
    orbs = Leaderboard.rank_orbs()
   {:ok,
    socket
    |> assign(users: users)
    |> assign(orb_view: false)
    |> assign(orbs: orbs)
  }
  end

  def handle_event("orb_count", _unsigned_params, socket) do
    users = Leaderboard.list_user_counts(:orbs)
    {:noreply,
    socket
    |> assign(users: users)
    |> assign(orb_view: false)
  }
  end

  def handle_event("ally_count", _, socket) do
    users = Leaderboard.list_user_counts(:relations)
    {:noreply,
    socket
    |> assign(users: users)
    |> assign(orb_view: false)
  }
  end

  def handle_event("comment_count", _, socket) do
    users = Leaderboard.list_user_counts(:comments)
    {:noreply,
    socket
    |> assign(users: users)
    |> assign(orb_view: false)
  }  end

  def handle_event("chat_count", _, socket) do
    users = Leaderboard.list_user_counts(:chats)
    {:noreply,
    socket
    |> assign(users: users)
    |> assign(orb_view: false)
  }  end

  def handle_event("orb_rank", _, socket) do
    {:noreply,
    socket
    |> assign(orb_view: true)
    }
  end
end
