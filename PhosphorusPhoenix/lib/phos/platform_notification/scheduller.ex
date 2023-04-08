defmodule Phos.PlatformNotification.Scheduller do
  require Logger

  use GenServer

  @default_timer :timer.minutes(5)

  alias Phos.PlatformNotification, as: PN

  @doc """
  start_link used to start this module and run the scheduller based on config
  """
  @spec start_link(opts :: Keyword.t()) :: :ok | :error
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do 
    Process.send_after(self(), :timer, timer())
    {:ok, []}
  end

  @impl true
  def handle_info(:timer, state) do
    notifications = PN.active_notification()
    now_time = current_time()
    Logger.debug("Running platform notification timer at #{now_time}")
    run_notification_timer(notifications)
    Process.send_after(self(), :timer, timer())
    {:noreply, state}
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
end
