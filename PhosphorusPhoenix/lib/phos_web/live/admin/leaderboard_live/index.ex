defmodule PhosWeb.Admin.LeaderboardLive.Index do
  use PhosWeb, :admin_view

  alias Phos.Repo
  alias Phos.Leaderboard

  def mount(_params, _session, socket) do
   {:ok,
      socket
    }
  end


  def handle_params(params, _url, socket) do
    sort_by = ((params["sort_by"]) || "username") |> String.to_atom()

    options = %{
      sort_by: sort_by
    }

    users = Leaderboard.rank_users(options)

    socket =
      assign(socket,
        users: users
      )

    {:noreply, socket}
  end
end
