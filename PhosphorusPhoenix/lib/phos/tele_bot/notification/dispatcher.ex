defmodule Phos.TeleBot.TelegramNotification.Dispatcher do
  use GenStage, restart: :permanent

  alias Phos.TeleBot.TelegramNotification, as: TN

  def start_link(_ok) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    # Process.send_after(self(), {:ask, from}, 5000)

    {:producer_consumer, %{}, subscribe_to: [{TN.Collector, max_demand: 30, interval: 2000}]}
  end

  def handle_subscribe(:producer, opts, from, producers) do
    pending = opts[:max_demand] || 1000
    interval = opts[:interval] || 2000

    producers = Map.put(producers, from, {pending, interval})
    producers = ask_and_schedule(producers, from)
    {:manual, producers}
  end

  # Make the subscriptions to auto for consumers
  def handle_subscribe(:consumer, _, _, state) do
    {:automatic, state}
  end

  def handle_cancel(_, from, producers) do
    {:noreply, Map.delete(producers, from)}
  end

  def handle_events(events, from, producers) do
    producers = Map.update!(producers, from, fn {pending, interval} ->
      {pending + length(events), interval}
    end)

    {:noreply, events, producers}
  end

  def handle_info({:ask, from}, producers) do
    {:noreply, [], ask_and_schedule(producers, from)}
  end

  def handle_demand({:ask, from}, producers) do
    {:noreply, [], ask_and_schedule(producers, from)}
  end

  defp ask_and_schedule(producers, from) do
    case producers do
      %{^from => {pending, interval}} ->
        # Ask for any pending events
        GenStage.ask(from, pending)
        # And let's check again after interval
        Process.send_after(self(), {:ask, from}, interval)
        # Finally, reset pending events to 0
        Map.put(producers, from, {0, interval})
      %{} ->
        producers
    end
  end
end
