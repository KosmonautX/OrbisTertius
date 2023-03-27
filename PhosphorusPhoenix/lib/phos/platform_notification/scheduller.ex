defmodule Phos.PlatformNotification.Scheduller do
  use GenServer

  @one_minute :timer.minutes(1)

  alias Phos.PlatformNotification.Store

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do 
    Process.send_after(self(), :timer, @one_minute)
    {:ok, []}
  end

  @impl true
  def handle_info(:timer, state) do
    notifications = Store.list()
    run_notification_timer(notifications)
    Process.send_after(self(), :timer, @one_minute)
    {:noreply, state}
  end

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
      "scheduled" -> Date.compare(date, DateTime.to_date(current_time)) == :eq
      "weekends" -> Timex.weekday(current_time) in [6, 7]
      "weekly" -> Timex.weekday(current_time) == 1
      _ -> Date.compare(date, DateTime.to_date(current_time)) == :eq
    end
  end

  defp singapore_timezone do
    %{year: year, month: month, day: day} = Date.utc_today()
    Timex.timezone("Asia/Singapore", {year, month, day})
  end

  defp current_time do
    DateTime.utc_now()
    |> Timex.Timezone.convert(singapore_timezone())
  end

  defp send_notification(elem) do
    # TODO: Need to know the query
    elem
  end
end
