defmodule Phos.Notification.Scheduller do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do 
    table = :ets.new(:notification_registry, [:set, :protected, read_concurrency: true])
    {:ok, table}
  end

  def fetch do
    # fetching from notion
    GenServer.cast(__MODULE__, :fetch)
  end

  def execute(id) do
    # execute the notification
    GenServer.call(__MODULE__, {:execute, id})
  end

  def renew do
    # delete last scheduller and fetch new
    GenServer.cast(__MODULE__, :renew)
  end

  def stop(id) do
    # stop
    GenServer.call(__MODULE__, {:stop, id})
  end

  def handle_cast(:fetch, state) do
    do_fetch_notification(state)
    {:noreply, state}
  end

  def handle_cast(:renew, state) do
    :ets.delete(state)
    do_fetch_notification(state)
    {:noreply, state}
  end

  def handle_cast({:execute, id}, state) do
    {data, _} = :ets.lookup(state, id)
    send_notification(data)
    {:noreply, state}
  end

  def handle_call({:stop, id}, _from, state) do
    case :ets.lookup(state, id) do
      {_data, false} -> {:reply, "Already stopped", state}
      {data, _} -> 
        :ets.delete(state, id)
        :ets.insert(state, {id, data, false})
        {:reply, data, state}
    end
  end

  def handle_call({:delete, id}, _from, state) do
    {data, _} = :ets.lookup(state, id)
    :ets.delete(state, id)
    {:reply, data, state}
  end

  defp do_fetch_notification(state) do
    Phos.Action.import_platform_notification()
    |> Enum.map(fn %{"id" => id} = value ->
      :ets.insert(state, {id, value, true})
    end)
  end

  defp send_notification(%{archetype: archetype, title: title} = data) when archetype != "-" do
    orb_decider(data)
    |> Enum.each(fn orb ->
      Phos.Notification.target(
        "#{archetype}.*",
        %{title: title, body: orb.title},
        PhosWeb.Util.Viewer.orb_mapper(orb))
    end)
  end

  defp send_notification(%{title: title} = data) do
    orb_decider(data)
    |> Enum.each(fn orb ->
      Phos.Notification.target(
        "*",
        %{title: title, body: orb.title},
        PhosWeb.Util.Viewer.orb_mapper(orb))
    end)
  end

  defp orb_decider(%{"regions" => []}), do: Phos.Action.list_all_active_orbs()
  defp orb_decider(%{"regions" => regions}) when is_list(regions) do
    Phos.External.Sector.get()
    |> Map.take(regions)
    |> Map.values()
    |> List.flatten()
    |> Enum.uniq()
    |> Phos.Action.active_orbs_by_geohashes()
  end
  defp orb_decider(_), do: []
end
