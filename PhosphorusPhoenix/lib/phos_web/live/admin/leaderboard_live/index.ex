defmodule PhosWeb.Admin.LeaderboardLive.Index do
  use PhosWeb, :admin_view

  alias Phos.Repo
  alias Phos.Leaderboard
  alias Phos.Action.Orb


  def mount(_params, _session, socket) do
    limit = 20
    page = 1
    startdt = DateTime.utc_now() |> DateTime.add(-7, :day)
    enddt = DateTime.utc_now()

    %{data: users, meta: user_meta} = Leaderboard.list_user_counts(limit, page, :orbs, [startdt: startdt, enddt: enddt])
    %{data: orbs} = Leaderboard.rank_orbs(limit, page)


    # %{data: orbs, meta: orb_meta} = Leaderboard.rank_orbs(limit, page)



    filters = %{startdate: startdt |> DateTime.to_date(), enddate: enddt |> DateTime.to_date()}

   {:ok,
    socket
    |> assign(orb_view: false)
    |> assign(orbs: orbs)
    |> assign(:filter_by, :orbs)
    |> assign(limit: limit)
    |> assign(:users, users)
    |> stream(:users, users)
    |> assign(:user_meta, user_meta)
    |> assign(:filters, filters)
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
      |> assign(user_list: users)
      |> assign(current: expected_page)
      |> assign(pagination: meta.pagination)
    }
  end

  # def handle_event("filter", _url, %{assigns: %{limit: limit, pagination: pagination}} = socket) do

  #   case option do
  #     "orbs" ->
  #       Leaderboard.list_user_counts(limit, pagination.current, :orbs)
  #     "allies" ->
  #       Leaderboard.list_user_counts(limit, pagination.current, :relations)
  #     "comments" ->
  #       Leaderboard.list_user_counts(limit, pagination.current, :comments)
  #     "chats" ->
  #       Leaderboard.list_user_counts(limit, pagination.current, :chats)
  #   end
  #   {:noreply, socket}
  # end

  def handle_params(_params, _url, socket), do: {:noreply, socket}

  def handle_event(
          "load-more",
          _,
          %{assigns: %{filters: %{startdate: startdt, enddate: enddt},limit: limit, user_meta: %{pagination: pagination}}} = socket
        ) do
      expected_page = pagination.current + 1

      %{data: newusers, meta: newmeta} = Leaderboard.list_user_counts(limit, expected_page, :orbs, [startdt: startdt, enddt: enddt])
      newsocket = Enum.reduce(newusers, socket, fn user, acc -> stream_insert(acc, :users, user) end)
      {:noreply, newsocket |> assign(user_meta: newmeta)}

  end
  def handle_event("filter", %{"filter_by" => option, "user" => %{"startdate" => startdate, "enddate" => enddate}} , %{assigns: %{filters: %{startdate: startdt, enddate: enddt}, limit: limit, user_meta: %{pagination: pagination} = user_meta}} = socket) do
    IO.inspect(option)
    with {:ok, startdt} <- NaiveDateTime.from_iso8601("#{startdate} 00:00:00"),
        {:ok, enddt} <- NaiveDateTime.from_iso8601("#{enddate} 23:59:59"),
        true <- NaiveDateTime.diff(startdt, enddt) < 0
      do
        %{data: users} = Leaderboard.list_user_counts(limit, pagination.current, String.to_atom(option), [startdt: startdt, enddt: enddt])
        {:noreply,
        socket
        |> stream(:users, users, reset: true)
        |> assign(user_meta: user_meta)
        |> assign(orb_view: false)
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



  defp parse_integer(text) do
    try do
      String.to_integer(text)
    rescue
      ArgumentError -> 1
    end
  end

  defp stream_assign(socket, key, %{data: data, meta: meta} = params) do
    socket
    |> stream(key, data)
    |> assign(key, meta)
  end

  defp user_fetcher(streamusers, currentUsers) do
    # IO.inspect(streamusers)
    newUsers = Enum.map(streamusers.inserts, fn {_, _, user, _} -> user end)
    currentUsers |> Enum.count() |> IO.inspect()
    newUsers
    # Enum.reduce(streamorbs.inserts, orbs, fn {_, _, orb, _}, acc -> [orb | acc] end)
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
