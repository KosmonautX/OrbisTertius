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
      {:ok, %{"template_id" => key} = data} ->
        template = PN.get_template_by_key(key)
        GenStage.reply(from, :ok)
        {:ok, stored} = PN.insert_notification(%{
          template_id: template.id,
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
    stored = PN.get_notification(id)
    retry_attempt = stored.retry_attempt + 1
    next_attempt = DateTime.add(DateTime.utc_now(), retry_attempt * stored.retry_after, :minute)
    PN.update_notification(stored, %{error_reason: message, next_try_at: next_attempt, retry_attempt: retry_attempt})
    {:noreply, [], state}
  end

  @impl true
  def handle_info({_ref, {id, :success, _message}}, state) do
    PN.update_notification(id, %{success: true})
    {:noreply, [], state}
  end

  defp filter_event_type(%{"type" => type} = data) when type in ["email", "push", "broadcast"] do
    {:ok, data}
  end
  defp filter_event_type(_data), do: :error

  defp filter_event_entity({:ok, %{"entity" => entity} = data}) when entity in ["ORB", "COMMENT"] do
    {:ok, data}
  end
  defp filter_event_entity(:error), do: :error
end
