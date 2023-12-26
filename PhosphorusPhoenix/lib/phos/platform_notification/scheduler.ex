defmodule Phos.PlatformNotification.Scheduler do
  use GenServer

  @default_timer :timer.minutes(5)

  alias Phos.PlatformNotification, as: PN

  @doc """
  start_link used to start this module and run the scheduler based on config
  """
  @spec start_link(opts :: Keyword.t()) :: :ok | :error
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do 
    Process.send_after(self(), :timer, timer())
    {:ok, []}
  end

  @impl true
  def handle_info(:execute, state) do
    GenStage.cast(PN.Dispatcher, :force_execute)
    {:noreply, state}
  end

  @impl true
  def handle_info(:timer, state) do
    now_time = current_time()
    :logger.debug(%{
      label: {Phos.PlatformNotification.Scheduler, :timer},
      report: %{
        module: __MODULE__,
        action: "scheduled timer every #{timer()}ms",
        current_time: now_time,
      }
    }, %{
      domain: [:phos],
      error_logger: %{tag: :debug_msg}
    })

    spawn(fn -> database_notification() end)
    spawn(fn -> notion_notification() end)

    Process.send_after(self(), :execute, 5_000)
    Process.send_after(self(), :timer, timer())
    {:noreply, state}
  end

  defp database_notification do
    :logger.debug(%{
      label: {Phos.PlatformNotification.Scheduler, :database_notification},
      report: %{
        module: __MODULE__,
        action: "execute failed/pending notification",
      }
    }, %{
      domain: [:phos],
      error_logger: %{tag: :debug_msg}
    })

    PN.active_notification(timer())
    |> run_notification_timer()
  end

  defp notion_notification do
    :logger.debug(%{
      label: {Phos.PlatformNotification.Scheduler, :notion_notification},
      report: %{
        module: __MODULE__,
        action: "executing global notification",
      }
    }, %{
      domain: [:phos],
      error_logger: %{tag: :debug_msg}
    })

    PN.Global.list()
    |> Enum.filter(fn n -> n.active end)
    |> Enum.map(&running_global_notification/1)
  end

  defp run_notification_timer([]), do: :ok
  defp run_notification_timer([notification | notifications]) do
    PN.notify(notification.id)
    run_notification_timer(notifications)
  end

  defp singapore_timezone do
    %{year: year, month: month, day: day} = Date.utc_today()
    Timex.timezone("Asia/Singapore", {year, month, day})
  end

  defp current_time do
    DateTime.utc_now()
    |> Timex.Timezone.convert(singapore_timezone())
  end

  defp timer() do
    PN.config()
    |> Keyword.get(:time_interval)
    |> case do
      int when is_integer(int) -> :timer.minutes(int)
      _ -> @default_timer
    end
  end

  defp running_global_notification(%{frequency: "weekends"} = data) do
    case Timex.weekday(current_time()) do
      d when d in [6, 7] -> do_send_global_notification(data)
      _ -> nil
    end
  end

  defp running_global_notification(%{frequency: "weekly"} = data) do
    case Timex.weekday(data.time_condition) == Timex.weekday(current_time()) do
      true -> do_send_global_notification(data)
      _ -> nil
    end
  end


  defp running_global_notification(%{frequency: "daily"} = data) do
      do_send_global_notification(data)
  end


  defp running_global_notification(%{frequency: _} = data) do
    IO.inspect data
  end

  defp do_send_global_notification(%{id: id, time_condition: time} = _data) do
    case Time.diff(current_time(), time) do
      t when t > 0 -> case t < timer() do
          true -> PN.Global.execute(id)
          _ -> nil
        end
      _ -> nil
    end
  end
end
