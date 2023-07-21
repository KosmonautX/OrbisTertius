defmodule Phos.TeleBot.TelegramNotification.Collector do
  use GenStage

  @moduledoc """

  """
  alias Phos.TeleBot.TelegramNotification, as: TN

  def start_link(_number) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:producer, :queue.new}
  end

  def add(%Phos.Action.Orb{} = orb, timeout \\ 5000) do
    events =
      Phos.Users.get_telegram_chat_ids_by_orb(orb) # List of %{orb: %Phos.Action.Orb{}}, chat_ids: "1234"}
    unless Enum.empty?(events), do: GenStage.call(__MODULE__, {:notify, events}, timeout)
  end

  def handle_call({:notify, event}, from, queue) do
    # enqueue items

    updated_queue =
      Enum.reduce(event, queue, fn msg, acc ->
        updated_queue = :queue.in(msg, acc)
      end)

    dispatch_events(updated_queue, :queue.len(updated_queue), from, [])
  end

  def handle_demand(incoming_demand, queue) do
    # take items from the queue and send them to the consumer
    dispatch_events(queue, incoming_demand + :queue.len(queue), [], [])
  end

  defp dispatch_events(queue, demand, _from, events) when demand == 0 do
    {:noreply, Enum.reverse(events), queue}
  end

  defp dispatch_events(queue, demand, from, events) do
    case :queue.out(queue) do
      {{:value, event}, queue} ->
        GenStage.reply(from, :ok)
        dispatch_events(queue, demand - 1, from, [event | events])
      {:empty, queue} ->
        {:noreply, Enum.reverse(events), queue}
    end
  end
end
