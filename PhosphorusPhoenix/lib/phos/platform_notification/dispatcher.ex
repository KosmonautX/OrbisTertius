defmodule Phos.PlatformNotification.Dispatcher do
  use GenStage

  alias Phos.PlatformNotification, as: PN

  def start_link(state) do
    GenStage.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    {:producer_consumer, 0, subscribe_to: conn_opts()}
  end

  defp conn_opts do
    opts = Keyword.take(PN.config(), [:max_demand, :min_demand])
    [{PN.Producer, opts}]
  end

  @impl true
  def handle_events([event | _rest], from, state) do
    event
    |> filter_event_type()
    |> filter_event_entity()
    |> case do
      {:ok, data} ->
        GenStage.reply(from, :ok)
        stored = PN.Store.insert(%{
          active: true,
          spec: data,
          id: Ecto.UUID.generate(),
        })

        {:noreply, [stored.id], state + 1}
      _ -> 
        GenStage.reply(from, :error)
        {:noreply, [], state}
    end
  end
  def handle_events(_events, _from, state), do: {:noreply, [], state}

  @impl true
  def handle_info({_ref, {id, type, message}}, state) when type in [:retry, :error] do
    stored = PN.Store.get(id)
    PN.Store.update(id, %{error_reason: message, last_try_at: DateTime.utc_now(), retry_attempt: stored.retry_attempt + 1})
    {:noreply, [], state}
  end

  @impl true
  def handle_info({_ref, {id, :success, _message}}, state) do
    PN.Store.update(id, %{last_try_at: DateTime.utc_now(), success: true})
    {:noreply, [], state}
  end

  defp filter_event_type({type, _entity, _id, _msg} = data) when type in [:email, :push, :broadcast] do
    {:ok, data}
  end
  defp filter_event_type(_data), do: :error

  defp filter_event_entity({:ok, {_type, entity, _id, _msg} = data}) when entity in ["USR", "ORB", "COMMENT"] do
    {:ok, data}
  end
  defp filter_event_entity(:error), do: :error
end
