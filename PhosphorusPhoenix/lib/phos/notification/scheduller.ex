defmodule Phos.Notification.Scheduller do
  use GenServer

  require Logger

  defstruct [:action_path, :active, :archetype, :archetype_id, :frequency, :id, :regions, :target_group, :title, :body , :time_condition, :trigger]

  @one_minute :timer.minutes(1)

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do 
    table = :ets.new(:notification_registry, [:set, :protected, read_concurrency: true])
    Process.send_after(self(), :timer, @one_minute)
    {:ok, table}
  end

  def fetch do
    # fetching from notion
    GenServer.cast(__MODULE__, :fetch)
  end

  def execute(id) do
    Logger.debug("Force executing notification with hash #{id}")
    # execute the notification
    GenServer.cast(__MODULE__, {:execute, id})
  end

  def get(id) do
    Logger.debug("Select notification with hash #{id}")
    # execute the notification
    GenServer.call(__MODULE__, {:get, id})
  end

  def list do
    GenServer.call(__MODULE__, :list)
  end

  def renew do
    Logger.debug("Renewing notification list")
    # delete last scheduller and fetch new
    GenServer.cast(__MODULE__, :renew)
  end

  def start(id) do
    Logger.debug("Update notification with hash #{id}")
    # start
    GenServer.call(__MODULE__, {:update_status, id, true})
  end

  def stop(id) do
    Logger.debug("Update notification with hash #{id}")
    # stop
    GenServer.call(__MODULE__, {:update_status, id, false})
  end

  @impl true
  def handle_cast(:fetch, state) do
    do_fetch_notification(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:renew, state) do
    :ets.delete(state)
    table = :ets.new(:notification_registry, [:set, :protected, read_concurrency: true])
    do_fetch_notification(table)
    {:noreply, table}
  end

  @impl true
  def handle_cast({:execute, id}, state) do
    case lookup(state, id) do
      {:ok, data, true} ->
        spawn(fn -> send_notification(data) end)
        {:noreply, state}
      _ -> {:noreply, state}
    end
  end

  @impl true
  def handle_call({:get, id}, _from, state) do
    case lookup(state, id) do
      {:ok, data, active} -> {:reply, Map.put(data, :active, active), state}
      _ -> {:reply, "data not found", state}
    end
  end

  @impl true
  def handle_call({:update_status, id, status}, _from, state) do
    case lookup(state, id) do
      {:ok, _data, current_status} when current_status == status -> {:reply, "Cannot update status", state}
      {:ok, %{id: id} = data, _current_status} -> 
        Phos.External.Notion.update_platform_notification(id, %{
          properties: %{"Active" => %{"checkbox" => status}}
        }) 
        GenServer.cast(__MODULE__, :renew)
        {:reply, Map.put(data, :active, status), state}
      _ -> {:reply, "data not found", state}
    end
  end

  @impl true
  def handle_call({:delete, id}, _from, state) do
    {:ok, data, _} = lookup(state, id)
    :ets.delete(state, id)
    {:reply, data, state}
  end

  @impl true
  def handle_call(:list, _from, state) do
    data = 
      :ets.tab2list(state)
      |> Enum.map(fn {_id, d, active} ->
        Map.put(d, :active, active)
      end)

    {:reply, data, state}
  end

  @impl true
  def handle_info(:timer, state) do
    notifications = :ets.tab2list(state)
    run_notification_timer(notifications)
    Process.send_after(self(), :timer, @one_minute)
    {:noreply, state}
  end

  defp do_fetch_notification(state) do
    Phos.Action.import_platform_notification()
    |> Enum.map(fn %{id: id} = value ->
      insert(state, id, value)
    end)
  end

  defp send_notification(%{regions: [_ | _], title: title} = data) do
    #expected_title = orb_title(title, orb)
    fetch_tokens(data)
    |> Phos.Notification.push(
      %{title: title, body: Map.get(data, :body, "")},
    %{action_path: data.action_path <> "/" <> data.archetype_id})
  end

  defp fetch_tokens(%{regions: regions}) when is_list(regions) do
    Phos.External.Sector.get()
    |> Map.take(regions)
    |> Map.values()
    |> List.flatten()
    |> Phos.Action.notifiers_by_geohashes()
    |> Enum.map(fn n -> Map.get(n, :fcm_token, nil) end)
  end

  defp fetch_tokens(_), do: []

  defp run_notification_timer(notifications) do
    now_time = current_time()
    Logger.debug("Running notification timer at #{now_time}")
    Enum.filter(notifications, fn {_id, %{time_condition: ntime, frequency: frequency}, _active} ->
      [date, time] = case ntime do
        %DateTime{} -> [DateTime.to_date(ntime), DateTime.to_time(now_time)]
        %Time{} -> [Timex.today, ntime]
      end

      diff = case should_execute?(frequency, date, now_time) do
        true -> Time.diff(time, ntime)
        _ -> -1
      end
      diff > 0 and diff < 60
    end)
    |> Enum.map(&Kernel.elem(&1, 1))
    |> Enum.each(&send_notification/1)
  end

  defp should_execute?(freq, date, current_time) do
    String.downcase(freq)
    |> case do
      "daily" -> true
      "now" -> true
      "scheduled" -> Date.compare(date, DateTime.to_date(current_time)) == :eq
      "weekends" -> Timex.weekday(current_time) in [6, 7]
      "weekly" -> Timex.weekday(current_time) == 1
      _ -> Date.compare(date, DateTime.to_date(current_time)) == :eq
    end
  end

  defp lookup(table, id) do
    case :ets.lookup(table, id) do
      [{_id, data, active}] -> {:ok, data, active}
      _ -> {:error, "data not found", false}
    end
  end

  defp insert(table, id, data) do
    active = Map.get(data, :active, false)
    schedule = struct(__MODULE__, data)
    :ets.insert(table, {id, schedule, active})
  end

  defp singapore_timezone do
    %{year: year, month: month, day: day} = Date.utc_today()
    Timex.timezone("Asia/Singapore", {year, month, day})
  end

  defp current_time do
    DateTime.utc_now()
    |> Timex.Timezone.convert(singapore_timezone())
  end

  defp orb_title(title, %Phos.Action.Orb{initiator: %{username: username}}) do
    constraint = "[InitiatorName]"
    case String.contains?(title, constraint) do
      true -> String.replace(title, constraint, username)
      _ -> title
    end
  end

  defp orb_title(title, _orb), do: title
end
