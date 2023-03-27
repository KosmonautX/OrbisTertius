defmodule Phos.PlatformNotification.Store do
  use GenServer

  defstruct [:action_path, :active, :archetype, :archetype_id, :frequency, :id, :regions, :target_group, :title, :body , :time_condition, :trigger]

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do 
    table = :ets.new(:platform_notification_registry, [:set, :protected, read_concurrency: true])
    {:ok, table}
  end

  def list do
    GenServer.call(__MODULE__, :list)
  end

  def get(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  def execute(id) do
    GenServer.cast(__MODULE__, {:execute, id})
  end

  def fetch do
    GenServer.cast(__MODULE__, :fetch)
  end

  def renew do
    GenServer.cast(__MODULE__, :renew)
  end

  @impl true
  def handle_cast(:renew, state) do
    :ets.delete(state)
    table = :ets.new(:notification_registry, [:set, :protected, read_concurrency: true])
    do_fetch_notification(table)
    {:noreply, table}
  end

  @impl true
  def handle_cast(:fetch, state) do
    do_fetch_notification(state)
    {:noreply, state}
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

  defp do_fetch_notification(state) do
    Phos.Action.import_platform_notification()
    |> Enum.map(fn %{id: id} = value ->
      insert(state, id, value)
    end)
  end

  defp send_notification(%{regions: [_ | _], title: title} = data) do
    fetch_tokens(data)
    |> Phos.Notification.push(
      %{title: title, body: Map.get(data, :body, "")},
    %{action_path: "#{data.action_path}/#{data.archetype_id}"})
  end

  defp fetch_tokens(%{regions: regions}) when is_list(regions) do
    Phos.External.Sector.get()
    |> Map.take(regions)
    |> Map.values()
    |> List.flatten()
    |> Phos.Action.notifiers_by_geohashes()
    |> Enum.map(fn n ->
      cond do
      is_map(n) == true ->
          Map.get(n, :fcm_token, nil)

      true ->
          nil
      end
    end)
    |> Enum.uniq()
  end

  defp fetch_tokens(_), do: []

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
end
