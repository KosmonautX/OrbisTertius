defmodule Phos.PlatformNotification.Consumer do
  use GenStage, restart: :permanent

  alias Phos.PlatformNotification, as: PN

  def start_link(_args) do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(arg) do
    {:consumer, arg, subscribe_to: [{PN.Dispatcher, config()}]}
  end

  defp config, do: Keyword.take(PN.config(), [:min_demand, :max_demand])

  def handle_events(events, from, state) do
    execute_events(events, from)

    {:noreply, [], state}
  end

  defp execute_events([], _from), do: :ok
  defp execute_events([event_id | tail], from) do
    case PN.get_notification(event_id) do
      %PN.Store{} = event -> execute_event(event, from)
      _ -> :not_found
    end

    execute_events(tail, from)
  end

  defp execute_event(%{spec: %{"type" => type}} = store, from) do
    consumer_executor = case type do
      t when t in ["broadcast", "push"] -> __MODULE__.Fcm
      "email" -> __MODULE__.Email
    end

    with {:ok, _result} <- apply(consumer_executor, :send, [store]) do
      GenStage.reply(from, {store.id, :success})
    else
      {:error, msg} -> GenStage.reply(from, {store.id, :error, msg})
      err -> GenStage.reply(from, {store.id, :unknown_error, err})
    end
  end
end
