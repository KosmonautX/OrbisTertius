defmodule PhosWeb.Admin.LeaderboardLive.Index do
  use PhosWeb, :admin_view

  alias Phos.Repo
  alias Phos.Leaderboard
  alias Phos.Action.Orb


  def mount(_params, _session, socket) do
    limit = 20
    page = 1
    startdt = DateTime.utc_now() |> DateTime.add(-365, :day)
    enddt = DateTime.utc_now()

    %{data: users, meta: user_meta} = Leaderboard.list_user_counts(limit, page, :orbs, [startdt: startdt, enddt: enddt])
    %{data: orbs} = Leaderboard.rank_orbs(limit, page)


    # %{data: orbs, meta: orb_meta} = Leaderboard.rank_orbs(limit, page)



    filter_dates = %{startdate: startdt |> DateTime.to_date(), enddate: enddt |> DateTime.to_date()}

   {:ok,
    socket
    |> assign(orb_view: false)
    |> assign(orbs: orbs)
    |> assign(:filter_by, "orbs")
    |> assign(limit: limit)
    |> assign(:users, users)
    |> stream(:users, users)
    |> assign(:user_meta, user_meta)
    |> assign(:filter_dates, filter_dates)
  }
  end

  def handle_params(_params, _url, socket), do: {:noreply, socket}

  def handle_event(
      "load-more",
      _,
      %{assigns: %{filter_by: option, filter_dates: %{startdate: startdate, enddate: enddate}, limit: limit, user_meta: %{pagination: pagination}}} = socket
      ) do
      IO.inspect(option)
      expected_page = pagination.current + 1

      with {:ok, startdt} <- NaiveDateTime.from_iso8601("#{startdate} 00:00:00"),
           {:ok, enddt} <- NaiveDateTime.from_iso8601("#{enddate} 23:59:59"),
           true <- NaiveDateTime.diff(startdt, enddt) < 0
      do
        %{data: newusers, meta: newmeta} = Leaderboard.list_user_counts(limit, expected_page, String.to_atom(option), [startdt: startdt, enddt: enddt])
        newsocket = Enum.reduce(newusers, socket, fn user, acc -> stream_insert(acc, :users, user) end)
        {:noreply, newsocket |> assign(user_meta: newmeta)}
      else
        _ -> {:noreply, socket}
      end

  end

  def handle_event("filter",
                  %{"filter_by" => option, "user" => %{"startdate" => startdate, "enddate" => enddate}},
                  %{assigns: %{limit: limit, user_meta: %{pagination: pagination} = user_meta}} = socket
                  ) do

      with {:ok, startdt} <- NaiveDateTime.from_iso8601("#{startdate} 00:00:00"),
           {:ok, enddt} <- NaiveDateTime.from_iso8601("#{enddate} 23:59:59"),
            true <- NaiveDateTime.diff(startdt, enddt) < 0
      do
        %{data: users} = Leaderboard.list_user_counts(limit, 1, String.to_atom(option), [startdt: startdt, enddt: enddt])
        {:noreply,
        socket
        |> stream(:users, users, reset: true)
        |> assign(user_meta: user_meta)
        |> assign(orb_view: false)
        |> assign(filter_by: option)
        }

      else
        _ -> {:noreply, socket}
      end

  end

  def handle_event("orb_rank", _, socket) do
    {:noreply,
    socket
    |> assign(orb_view: true)
    }
  end

  defp stream_assign(socket, key, %{data: data, meta: meta} = params) do
    socket
    |> stream(key, data)
    |> assign(key, meta)
  end

  # def multi_filter_orbs(filters, opts \\ []) do
  #   page = Keyword.get(opts, :page, 1)
  #   limit = Keyword.get(opts, :limit, 20)
  #   sort_attribute = Keyword.get(opts, :sort_attribute, :inserted_at)
  #   startdt = Keyword.get(filters, :startdt)
  #   enddt = Keyword.get(filters, :enddt)

  #   query =
  #     [
  #       &where(&1, [o], o.inserted_at > ^startdt),
  #       &where(&1, [o], o.inserted_at < ^enddt)
  #     ]
  #     |> Enum.reduce(Phos.Action.Orb, fn x, acc -> acc |> x.() end)
  #     |> preload(:initiator)

  #     Repo.Paginated.all(query, page, sort_attribute, limit)
  # end
end
