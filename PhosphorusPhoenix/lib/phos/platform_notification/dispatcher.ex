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
      {:reply, %{"notification_id" => id}} when not is_nil(id) ->
        GenStage.reply(from, :ok)
        {:noreply, [id], state + 1}
      
      {:ok, data} ->
        case insert_to_persistent_database(data) do
          {:ok, stored} ->
            GenStage.reply(from, :ok)
            {:noreply, [stored.id], state + 1}
          {:error, msg} -> 
            GenStage.reply(from, {:error, msg})
            {:noreply, [], state}
        end
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
    next_attempt = DateTime.add(DateTime.utc_now(), retry_attempt * retry_after(), :minute)
    PN.update_notification(stored, %{error_reason: message, next_execute_at: next_attempt, retry_attempt: retry_attempt, success: retry_attempt > 5})
    {:noreply, [], state}
  end

  @impl true
  def handle_info({_ref, {id, :success}}, state) do
    stored = PN.get_notification(id)
    PN.update_notification(stored, %{success: true})
    {:noreply, [], state}
  end

  defp filter_event_type(%{"type" => type} = data) when type in ["email", "push", "broadcast"] do
    {:ok, data}
  end
  defp filter_event_type(%{"notification_id" => _id} = data), do: {:reply, data}
  defp filter_event_type(_data), do: :error

  defp filter_event_entity({:ok, %{"entity" => entity} = data}) when entity in ["ORB", "COMMENT"] do
    {:ok, data}
  end
  defp filter_event_entity({:reply, %{"notification_id" => _id} = data}), do: {:reply, data}
  defp filter_event_entity(:error), do: :error

  defp retry_after do
    PN.config()
    |> Keyword.get(:time_interval)
    |> case do
      int when is_integer(int) -> int
      _ -> 5
    end
  end

  defp insert_to_persistent_database(%{"template_id" => key} = data) when not is_nil(key) do
    template = PN.get_template_by_key(key) || %{}
    case get_recepient(data) do
      {:ok, recepient_id} -> PN.insert_notification(%{
          template_id: Map.get(template, :id),
          recepient_id: recepient_id,
          spec: data,
          id: Ecto.UUID.generate(),
        })
      err -> err
    end
  end
  defp insert_to_persistent_database(data)  do
    case get_recepient(data) do
      {:ok, recepient_id} -> PN.insert_notification(%{
          recepient_id: recepient_id,
          active: true,
          spec: data,
          id: Ecto.UUID.generate(),
        })
      err -> err
    end
  end

  defp get_recepient(%{"options" => opts}) do
    case Map.get(opts, "to") do
      user when is_bitstring(user) -> {:ok, user}
      _ -> {:error, "Options to: must be included"}
    end
  end
end
