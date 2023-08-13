defmodule Phos.PlatformNotification.Global do
  use GenServer

  defstruct [
    :action_path,
    :active,
    :archetype,
    :archetype_id,
    :frequency,
    :id,
    :regions,
    :target_group,
    :title,
    :body,
    :time_condition,
    :trigger
  ]

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    table =
      :ets.new(:platform_notification_global_registry, [:set, :protected, read_concurrency: true])

    {:ok, table}
  end

  def fetch do
    # fetching from notion
    GenServer.cast(__MODULE__, :fetch)
  end

  def execute(id) do
    :logger.debug(
      %{
        label: {Phos.PlatformNotification.Global, "execute notification with certain id"},
        report: %{
          module: __MODULE__,
          id: id
        }
      },
      %{
        domain: [:phos],
        error_logger: %{tag: :debug_msg}
      }
    )

    # execute the notification
    GenServer.cast(__MODULE__, {:execute, id})
  end

  def get(id) do
    :logger.debug(
      %{
        label: {Phos.PlatformNotification.Global, "get global notification with id"},
        report: %{
          module: __MODULE__,
          id: id
        }
      },
      %{
        domain: [:phos],
        error_logger: %{tag: :debug_msg}
      }
    )

    # execute the notification
    GenServer.call(__MODULE__, {:get, id})
  end

  def list do
    GenServer.call(__MODULE__, :list)
  end

  def renew do
    :logger.debug(
      %{
        label: {Phos.PlatformNotification.Global, "renewing all global notification"},
        report: %{
          module: __MODULE__,
          action: :renew
        }
      },
      %{
        domain: [:phos],
        error_logger: %{tag: :debug_msg}
      }
    )

    # delete last scheduller and fetch new
    GenServer.cast(__MODULE__, :renew)
  end

  def start(id) do
    :logger.debug(
      %{
        label: {Phos.PlatformNotification.Global, "update global notification with id"},
        report: %{
          module: __MODULE__,
          action: :start,
          id: id
        }
      },
      %{
        domain: [:phos],
        error_logger: %{tag: :debug_msg}
      }
    )

    # start
    GenServer.call(__MODULE__, {:update_status, id, true})
  end

  def stop(id) do
    :logger.debug(
      %{
        label: {Phos.PlatformNotification.Global, "update global notification with id"},
        report: %{
          module: __MODULE__,
          action: :stop,
          id: id
        }
      },
      %{
        domain: [:phos],
        error_logger: %{tag: :debug_msg}
      }
    )

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
        send_notification(data)
        {:noreply, state}

      _ ->
        {:noreply, state}
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
      {:ok, _data, current_status} when current_status == status ->
        {:reply, "Cannot update status", state}

      {:ok, %{id: id} = data, _current_status} ->
        Phos.External.Notion.update_platform_notification(id, %{
          properties: %{"Active" => %{"checkbox" => status}}
        })

        GenServer.cast(__MODULE__, :renew)
        {:reply, Map.put(data, :active, status), state}

      _ ->
        {:reply, "data not found", state}
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

  defp send_notification(%{regions: regions, action_path: action_path, archetype_id: id} = data) do
    # {:ok, mem} = Phos.Message.create_memory(%{user_source_id: Phos.Users.get_admin().id, orb_subject_id: id, message: "pltfrm_orb"})
    Phos.External.Sector.get()
    |> Map.take(regions)
    |> Map.values()
    |> List.flatten()
    |> Phos.Action.notifiers_by_geohashes()
    |> Enum.map(fn n -> n && Map.get(n, :fcm_token, nil) end)
    |> MapSet.new()
    # |> batch
    |> tap(fn batch ->
      Enum.chunk_every(batch, 499)
      |> Enum.map(fn tokens ->
        Sparrow.FCM.V1.Notification.new(:token, tokens, data.title, data.body, %{
          action_path: action_path <> "/#{id}",
          cluster_id: "platform"
        })
      end)
      |> Enum.map(fn geonotif ->
        geonotif
        |> Sparrow.API.push()
      end)
    end)
  end
end
