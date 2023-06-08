defmodule PhosWeb.Admin.LeaderboardLive.Index do
  use PhosWeb, :admin_view
  alias Phos.Leaderboard

  def mount(_params, _session, socket) do
   {:ok,
    socket
    |> setup_assign()
    }
  end

  def handle_event(
    "load-more-users",
    _,
    %{assigns: %{filter_by: option, filter_dates: %{} = filter_dates, limit: limit, user_meta: %{pagination: pagination}}} = socket
    ) do
    expected_page = pagination.current + 1

    with {:ok, %{startdt: startdt, enddt: enddt}} <- get_naive_dates(filter_dates) do
      %{data: new_users, meta: new_meta} = Leaderboard.list_user_counts(limit, expected_page, String.to_atom(option), [startdt: startdt, enddt: enddt])
      newsocket = Enum.reduce(new_users, socket, fn user, acc -> stream_insert(acc, :users, user) end)

      {:noreply,
      newsocket
      |> assign(user_meta: new_meta)}
    else
      _ -> {:noreply, socket}
    end

  end

  def handle_event(
    "load-more-orbs",
    _,
    %{assigns: %{limit: limit, orb_meta: %{pagination: pagination}}} = socket
    ) do
    expected_page = pagination.current + 1

    %{data: new_orbs, meta: new_meta} = Leaderboard.rank_orbs(limit, expected_page)
    newsocket = Enum.reduce(new_orbs, socket, fn orb, acc -> stream_insert(acc, :orbs, orb) end)

    {:noreply,
    newsocket
    |> assign(orb_meta: new_meta)}

  end

  def handle_event(
    "filter",
    %{"filter_by" => option, "user" => %{"startdate" => startdate, "enddate" => enddate}},
    %{assigns: %{limit: limit}} = socket
    ) do

    filter_dates = %{startdate: startdate, enddate: enddate}

    with {:ok, %{startdt: startdt, enddt: enddt}} <- get_naive_dates(filter_dates) do
      %{data: new_users, meta: new_meta} = Leaderboard.list_user_counts(limit, 1, String.to_atom(option), [startdt: startdt, enddt: enddt])

      {:noreply,
      socket
      |> stream(:users, new_users, reset: true)
      |> assign(user_meta: new_meta)
      |> assign(orb_view: false)
      |> assign(filter_by: option)
      |> assign(filter_dates: filter_dates)
      }

    else
      _ -> {:noreply, socket}
    end

  end

  def handle_event("reset-users", _, socket) do

    {:noreply,
     socket
     |> stream(:users, [], reset: true)
     |> stream(:orbs, [], reset: true)
     |> setup_assign()
    }
   end

  def handle_event("orb_rank", _, socket) do
    limit = 40
    page = 1

    %{data: orbs, meta: orb_meta} = Leaderboard.rank_orbs(limit, page)

    {:noreply,
    socket
    |> assign(orb_view: true)
    |> assign(orb_meta: orb_meta)
    |> stream(:orbs, orbs)
    }

  end

  defp setup_assign(socket) do
    limit = 40
    page = 1
    startdt = DateTime.utc_now() |> DateTime.add(-60, :day)
    enddt = DateTime.utc_now()

    %{data: users, meta: user_meta} = Leaderboard.list_user_counts(limit, page, :orbs, [startdt: startdt, enddt: enddt])

    filter_dates = %{startdate: startdt |> DateTime.to_date(), enddate: enddt |> DateTime.to_date()}

    socket
    |> assign(orb_view: false)
    |> assign(:filter_by, "orbs")
    |> assign(:filter_dates, filter_dates)
    |> assign(limit: limit)
    |> assign(:user_meta, user_meta)
    |> stream(:users, users)

  end

  defp get_naive_dates(%{startdate: startdate, enddate: enddate} = filter_dates) do

    with {:ok, startdt} <- NaiveDateTime.from_iso8601("#{startdate} 00:00:00"),
      {:ok, enddt} <- NaiveDateTime.from_iso8601("#{enddate} 23:59:59"),
      true <- NaiveDateTime.diff(startdt, enddt) < 0
    do
      {:ok, %{startdt: startdt, enddt: enddt}}

    else
      _ ->
        {:error, filter_dates}

    end
  end

end
