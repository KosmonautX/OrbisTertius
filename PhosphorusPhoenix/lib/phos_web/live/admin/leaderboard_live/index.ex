defmodule PhosWeb.Admin.LeaderboardLive.Index do
  use PhosWeb, :admin_view
  alias Phos.Leaderboard

  def mount(_params, _session, socket) do
   {:ok,
    socket
    |> setup_assign()
    }
  end

  def handle_params( %{"see_top" => see_top, "filter_by" => option, "user" => %{"startdate" => startdate, "enddate" => enddate}}, _url, socket) do
    filter_dates = %{startdate: startdate, enddate: enddate}
    case see_top do
      "See Top Orbs By" ->
        send(self(), :filter_orbs)

        # {:ok, %{startdt: startdt, enddt: enddt}} = get_naive_dates(socket.assigns.filter_dates)
        # %{data: orbs, meta: orb_meta} = Leaderboard.rank_orbs(socket.assigns.limit, 1, [startdt: startdt, enddt: enddt])


        {:noreply, socket
        |> assign(:current_view, "See Top Orbs By")
        |> assign(:filter_by, option)
        |> assign(:filter_dates, filter_dates)

        # |> assign(orb_meta: orb_meta)
        # |> stream(:orbs, orbs, reset: true)
        }

      "See Top Users By" ->
        send(self(), :filter_users)

        # {:ok, %{startdt: startdt, enddt: enddt}} = get_naive_dates(socket.assigns.filter_dates)
        # %{data: new_users, meta: new_meta} = Leaderboard.list_user_counts(socket.assigns.limit, 1, option_to_atom(socket.assigns.filter_by), [startdt: startdt, enddt: enddt])


        {:noreply, socket
        |> assign(:current_view, "See Top Users By")
        |> assign(:filter_by, option)
        |> assign(:filter_dates, filter_dates)

        # |> assign(user_meta: new_meta)
        # |> stream(:users, new_users, reset: true)
        }

      _ ->
        {:noreply, socket}
    end

  end

  def handle_params(_, _, socket), do: {:noreply, socket}


  def handle_info(:filter_orbs, socket) do

    {:ok, %{startdt: startdt, enddt: enddt}} = get_naive_dates(socket.assigns.filter_dates)
    %{data: orbs, meta: orb_meta} = Leaderboard.rank_orbs(socket.assigns.limit, 1, [startdt: startdt, enddt: enddt])

    {:noreply,
    socket
    |> assign(orb_meta: orb_meta)
    |> stream(:orbs, orbs, reset: true)
    }
  end

  def handle_info(:filter_users, socket) do

    {:ok, %{startdt: startdt, enddt: enddt}} = get_naive_dates(socket.assigns.filter_dates)
    %{data: new_users, meta: new_meta} = Leaderboard.list_user_counts(socket.assigns.limit, 1, option_to_atom(socket.assigns.filter_by), [startdt: startdt, enddt: enddt])
    {:noreply,
    socket
    |> assign(user_meta: new_meta)
    |> stream(:users, new_users, reset: true)}
  end

  def handle_event("update_options", _, %{assigns: %{current_view: current_view}} = socket) do
    case current_view do
      "See Top Users By" ->
        {:noreply,
          socket
          |> assign(:count_options, ["Orbs", "Allies", "Chats", "Comments"])
          |> assign(:filter_by, "Orbs")

        }

      "See Top Orbs By" ->
        {:noreply,
          socket
          |> assign(:count_options, ["Comments"])
          |> assign(:filter_by, "Comments")
        }

    end

  end

  def handle_event(
    "load-more-users",
    _,
    %{assigns: %{filter_by: option, filter_dates: %{} = filter_dates, limit: limit, user_meta: %{pagination: pagination}}} = socket
    ) do
    expected_page = pagination.current + 1

    with {:ok, %{startdt: startdt, enddt: enddt}} <- get_naive_dates(filter_dates) do
      %{data: new_users, meta: new_meta} = Leaderboard.list_user_counts(limit, expected_page, option_to_atom(option), [startdt: startdt, enddt: enddt])

      {:noreply,
      socket
      |> assign(user_meta: new_meta)
      |> stream(:users, new_users)
      }
    else
      _ -> {:noreply, socket}
    end

  end

  def handle_event(
    "load-more-orbs",
    _,
    %{assigns: %{limit: limit, filter_dates: %{} = filter_dates, orb_meta: %{pagination: pagination} = orb_meta }} = socket
    ) do
    expected_page = pagination.current + 1
    {:ok, %{startdt: startdt, enddt: enddt}} = get_naive_dates(filter_dates)
    %{data: new_orbs, meta: new_meta} = Leaderboard.rank_orbs(limit, expected_page, [startdt: startdt, enddt: enddt])

    {:noreply,
    socket
    |> assign(orb_meta: new_meta)
    |> stream(:orbs, new_orbs)
    }

  end

  def handle_event("reset", params, socket) do

    {:noreply,
     socket
     |> stream(:users, [], reset: true)
     |> stream(:orbs, [], reset: true)
     |> setup_assign()
    }
   end

  defp setup_assign(socket) do
    limit = 20
    page = 1
    startdt = DateTime.utc_now() |> DateTime.add(-60, :day)
    enddt = DateTime.utc_now()
    filter_dates = [startdt: startdt, enddt: enddt]

    %{data: users, meta: user_meta} = Leaderboard.list_user_counts(limit, page, :orbs, filter_dates)
    %{data: orbs, meta: orb_meta} = Leaderboard.rank_orbs(limit, 1, filter_dates)

    filter_dates = %{startdate: startdt |> DateTime.to_date(), enddate: enddt |> DateTime.to_date()}

    socket
    |> assign(:top_options, ["See Top Users By", "See Top Orbs By" ])
    |> assign(:count_options, ["Orbs", "Allies", "Chats", "Comments"])
    |> assign(:current_view, "See Top Users By")
    |> assign(:filter_by, "Orbs")
    |> assign(:filter_dates, filter_dates)
    |> assign(limit: limit)
    |> assign(:user_meta, user_meta)
    |> assign(:orb_meta, orb_meta)
    |> stream(:users, users)
    |> stream(:orbs, orbs)

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


  defp option_to_atom(option) do

    option
    |> String.downcase()
    |> String.to_atom()

  end





end
