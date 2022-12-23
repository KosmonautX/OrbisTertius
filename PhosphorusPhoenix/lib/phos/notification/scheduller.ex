defmodule Phos.Notification.Scheduller do
  use GenServer

  require Logger

  defstruct [:active, :archetype, :body, :frequency, :id, :pathing, :regions, :target_group, :time_condition, :title]

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

  defp send_notification(%{archetype: archetype, title: title} = data) when archetype != "-" do
    orb_decider(data)
    |> Enum.each(fn orb ->
      expected_title = orb_title(title, orb)
      Phos.Notification.target(
        "#{archetype}.*",
        %{title: expected_title, body: orb.title},
        PhosWeb.Util.Viewer.orb_mapper(orb))
    end)
  end

  defp send_notification(%{title: title} = data) do
    orb_decider(data)
    |> Enum.each(fn orb ->
      expected_title = orb_title(title, orb)
      Phos.Notification.target(
        "*",
        %{title: expected_title, body: orb.title},
        PhosWeb.Util.Viewer.orb_mapper(orb))
    end)
  end

  defp orb_decider(%{regions: []}), do: Phos.Action.list_all_active_orbs()
  defp orb_decider(%{regions: regions}) when is_list(regions) do
    Phos.External.Sector.get()
    |> Map.take(regions)
    |> Map.values()
    |> List.flatten()
    |> Enum.uniq()
    |> Phos.Action.active_orbs_by_geohashes()
  end
  defp orb_decider(_), do: []

  defp run_notification_timer(notifications) do
    time = current_time()
    Logger.debug("Running notification timer at #{time}")
    Enum.filter(notifications, fn {_id, n, _active} ->
      ntime = Map.get(n, :time_condition)
      diff = Time.diff(time, ntime)
      diff > 0 and diff < 60
    end)
    |> Enum.map(&Kernel.elem(&1, 1))
    |> Enum.each(&send_notification/1)
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
    |> DateTime.to_time()
  end

  defp orb_title(title, %Phos.Action.Orb{initiator: %{username: username}}) do
    constraint = "[InitiaorName]"
    case String.contains?(title, constraint) do
      true -> String.replace(title, constraint, username)
      _ -> title
    end
  end
  defp orb_title(title, _orb), do: title
end
