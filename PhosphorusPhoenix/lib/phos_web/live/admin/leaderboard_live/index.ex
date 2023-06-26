defmodule PhosWeb.Admin.LeaderboardLive.Index do
  use PhosWeb, :admin_view
  alias Phos.Leaderboard

  def mount(_params, _session, socket) do

    limit = 20
    page = 1
    startdt = DateTime.utc_now() |> DateTime.add(-366, :day)
    enddt = DateTime.utc_now()

    %{meta: user_meta} = Leaderboard.list_user_counts(limit, page, :orbs, [startdt: startdt, enddt: enddt])
    %{meta: orb_meta} = Leaderboard.rank_orbs(limit, 1, [startdt: startdt, enddt: enddt])

    filter_dates = %{"startdate" => startdt |> DateTime.to_date(), "enddate" => enddt |> DateTime.to_date()}

    {:ok,
    socket
    |> assign(:filter_options, ["Allies", "Chats", "Comments", "Orbs"])
    |> assign(:current_view, "See Top Users By")
    |> assign(:filter_by, "Allies")
    |> assign(:filter_dates, filter_dates)
    |> assign(limit: limit)
    |> assign(:user_meta, user_meta)
    |> assign(:orb_meta, orb_meta)
    |> stream(:users, [])
    |> stream(:orbs, [])
    }

  end

  def handle_params(%{"form" => %{}} = params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def handle_params(_, _, socket), do: {:noreply, socket}


  def handle_event("change", %{"see_top" => "See Top Users By"} = params,  socket) do
    {:noreply, socket
    |> apply_action(:user, params)
    |> push_patch(to: ~p"/admin/leaderboard/")
    }
  end

  def handle_event("change", %{"see_top" => "See Top Orbs By"} = params,  socket) do
    {:noreply,
    socket
    |> apply_action(:orb, params)
    |> push_patch(to: ~p"/admin/leaderboard/orb")
    }
  end

  def handle_event("change", %{"_target" => ["reset"]},  socket) do
    {:noreply, push_navigate(socket, to: ~p"/admin/leaderboard")}
  end

  def handle_event("change", _, socket), do: {:noreply, socket}


  def handle_event(
    "load-more-users",
    _,
    %{assigns: %{filter_by: option, filter_dates: %{} = filter_dates, limit: limit, user_meta: %{pagination: pagination}}} = socket
    ) do

    expected_page = pagination.current + 1

    with %{startdt: startdt, enddt: enddt} <- get_naive_dates(socket, filter_dates) do
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
    %{assigns: %{limit: limit, filter_dates: %{} = filter_dates, orb_meta: %{pagination: pagination} }} = socket
    ) do

    expected_page = pagination.current + 1
    %{startdt: startdt, enddt: enddt} = get_naive_dates(socket, filter_dates)
    %{data: new_orbs, meta: new_meta} = Leaderboard.rank_orbs(limit, expected_page, [startdt: startdt, enddt: enddt])

    {:noreply,
    socket
    |> assign(orb_meta: new_meta)
    |> stream(:orbs, new_orbs)
    }

  end

  defp apply_action(socket, :user, params) do

    %{startdt: startdt, enddt: enddt} = get_naive_dates(socket, params["form"])

    %{data: users, meta: user_meta} = Leaderboard.list_user_counts(socket.assigns.limit, 1, option_to_atom(params["filter_by"]), [startdt: startdt, enddt: enddt])

    socket
    |> assign(:filter_options, ["Allies", "Chats", "Comments", "Orbs"])
    |> assign(:current_view, "See Top Users By")
    |> assign(:filter_by, params["filter_by"])
    |> assign(:filter_dates, params["form"])
    |> assign(:user_meta, user_meta)
    |> stream(:users, users, reset: true)
  end

  defp apply_action(socket, :orb, params) do
    %{startdt: startdt, enddt: enddt} = get_naive_dates(socket, params["form"])
    %{data: orbs, meta: orb_meta} = Leaderboard.rank_orbs(socket.assigns.limit, 1, [startdt: startdt, enddt: enddt])

    socket
    |> assign(:filter_options, ["Comments"])
    |> assign(:current_view, "See Top Orbs By")
    |> assign(:filter_by, params["filter_by"])
    |> assign(:filter_dates, params["form"])
    |> assign(:orb_meta, orb_meta)
    |> stream(:orbs, orbs, reset: true)

  end

  defp get_naive_dates(_socket, %{"startdate" => startdate, "enddate" => enddate} = filter_dates) do

    with {:ok, startdt} <- NaiveDateTime.from_iso8601("#{startdate} 00:00:00"),
      {:ok, enddt} <- NaiveDateTime.from_iso8601("#{enddate} 23:59:59"),
      true <- NaiveDateTime.diff(startdt, enddt) < 0
    do
      %{startdt: startdt, enddt: enddt}

    else
      _ ->
        {:error, filter_dates}
    end

  end

  defp get_naive_dates(socket, _) do
    {:ok, startdt} = NaiveDateTime.from_iso8601("#{socket.assigns.filter_dates["startdate"]} 00:00:00")
    {:ok, enddt} = NaiveDateTime.from_iso8601("#{socket.assigns.filter_dates["enddate"]} 23:59:59")
    %{startdt: startdt, enddt: enddt}
  end

  defp option_to_atom(option) do
    option
    |> String.downcase()
    |> String.to_atom()
  end


end
