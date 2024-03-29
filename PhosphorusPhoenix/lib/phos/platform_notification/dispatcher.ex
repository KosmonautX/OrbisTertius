defmodule Phos.PlatformNotification.Dispatcher do
  use GenStage

  alias Phos.Repo
  alias Phos.PlatformNotification, as: PN

  def start_link(state) do
    GenStage.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    {:producer_consumer, [], subscribe_to: conn_opts()}
  end

  defp conn_opts do
    opts = Keyword.take(PN.config(), [:max_demand, :min_demand])
    [{PN.Producer, opts}]
  end

  @impl true
  def handle_events([event | _rest], from, state) do
    GenStage.reply(from, :ok)
    Process.send_after(self(), :dispatch, 100)
    case emitter(event, state) do
      {:ok, emit} -> {:noreply, [], [emit | state]}
      _ -> {:noreply, [], state}
    end
  end
  def handle_events(_events, _from, state), do: {:noreply, [], state}

  @impl true
  def handle_cast(:force_execute, state) do
    {:noreply, state, []}
  end

  @impl true
  def handle_info({_ref, {id, type, message}}, state) when type in [:retry, :error, :unknown_error] and not is_nil(id) do
    stored = PN.get_notification(id)
    _ = increment_retry_logic(stored, message)
    {:noreply, [], state}
  end

  @impl true
  def handle_info({_ref, {id, :error, message}}, state) when is_bitstring(id) do
    PN.update_notifications(id, %{error_reason: inspect(message), retry_attempt: 6, success: false})
    {:noreply, [], state}
  end

  @impl true
  def handle_info({_ref, {id, :UNREGISTERED = err, _message}}, state) do
    with %{recipient: user} = notif <- PN.get_notification(id),
         _ <- increment_retry_logic(notif, err), # change the fcm_token to nil cause INVALID_ARGUMENT from sparrow
         {:ok, _} <- Phos.Users.update_integrations_user(user, %{"integrations" => %{"fcm_token" => nil}}) do
      {:noreply, [], state}
    else
      _ -> {:noreply, [], state}
    end
  end

  @impl true
  def handle_info({_ref, {id, :INVALID_ARGUMENT, _message}}, state) do 
    stored = PN.get_notification(id)
    increment_retry_logic(stored, :INVALID_ARGUMENT) # thow to invalid state
    {:noreply, [], state}
  end

  @impl true
  def handle_info({_ref, {_id, :QUOTA_EXCEEDED, _message}}, state), do: {:noreply, [], state}

  @impl true
  def handle_info({_ref, {id, :success}}, state) do
    stored = PN.get_notification(id)
    PN.update_notification(stored, %{success: true})
    {:noreply, [], state}
  end

  @impl true
  def handle_info(:dispatch, state) when length(state) >= 500 do
    {events_to_dispatch, remaining_events} = Enum.split(state, max_demand())
    {:noreply, events_to_dispatch, remaining_events}
  end

  @impl true
  def handle_info(:dispatch, state) do
    {:noreply, [], state}
  end

  def handle_info(_, _msg, state) do
    {:noreply, [], state}
  end

  defp filter_event_type(%{"type" => type} = data) when type in ["email", "push", "broadcast"] do
    {:ok, data}
  end
  defp filter_event_type(%{"notification_id" => _id} = data), do: {:reply, data}
  defp filter_event_type(_data), do: :error

  defp filter_event_entity({:ok, %{"entity" => entity} = data}) when entity in ["ORB", "COM", "PINNED"] do
    {:ok, data}
  end
  defp filter_event_entity({:reply, %{"notification_id" => _id} = data}), do: {:reply, data}
  defp filter_event_entity(:error), do: :error

  defp increment_retry_logic(notification, message) do
    retry_attempt = retry_by_error(notification, message)
    next_attempt = next_attempt_by_error(retry_attempt, message)
    PN.update_notification(notification, %{error_reason: inspect(message), next_execute_at: next_attempt, retry_attempt: retry_attempt, success: false})
  end

  defp retry_by_error(_notif, :INVALID_ARGUMENT), do: 6 # invalid argument cannot be retried
  defp retry_by_error(notification, _msg), do: notification.retry_attempt + 1

  defp next_attempt_by_error(delay, :INVALID_ARGUMENT), do: DateTime.add(DateTime.utc_now(), -delay * retry_after(), :minute) # add backdate
  defp next_attempt_by_error(delay, _), do: DateTime.add(DateTime.utc_now(), delay * retry_after(), :minute)

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
      with {:ok, recipient_id} <- get_recipient(data),
           {:ok, memory} <- get_memory(data) do
        PN.insert_notification(%{
          template_id: Map.get(template, :id),
          recipient_id: recipient_id,
          memory: memory,
          spec: data,
          id: Ecto.UUID.generate(),
        })
      else
        err -> err
      end
  end

  defp insert_to_persistent_database(data)  do
    case get_recipient(data) do
      {:ok, recipient_id} -> PN.insert_notification(%{
          recipient_id: recipient_id,
          active: true,
          spec: data,
          id: Ecto.UUID.generate(),
        })
      err -> err
    end
  end

  defp get_recipient(%{"options" => opts}) do
    case Map.get(opts, "to") do
      user when is_bitstring(user) -> {:ok, user}
      _ -> {:error, "Options to: must be included"}
    end
  end

  defp get_memory(%{"options" => opts}) do
    case Map.get(opts, "memory") do
      memory when is_map(memory) -> {:ok, memory}
      _ -> {:error, "Memories to be included"}
    end
  end

  defp max_demand do
    PN.config()
    |> Keyword.get(:max_demand, 500)
  end

  defp emitter(event, state) do
    event
    |> filter_event_type()
    |> filter_event_entity()
    |> case do
      {:reply, %{"notification_id" => id} = _data} when not is_nil(id) ->
        Enum.filter(state, &Kernel.==(&1.id, id))
        |> Kernel.length()
        |> Kernel.==(1)
        |> case do
          true -> {:error, "Notification exists"}
          _ -> {:ok, PN.get_notification(id)}
        end
      {:ok, data} ->
        case insert_to_persistent_database(data) do
          {:ok, stored} -> {:ok,
                           Repo.preload(stored, [:recipient, [memory: [:orb_subject, :com_subject, :user_source]]])
                           |> tap(fn
                             %{recipient: u, memory: %Phos.Message.Memory{} = m} ->
                               Phos.PubSub.publish(m, {:memory, "activity"}, u)
                           _ -> :ok end)}
          {:error, _msg} = ret -> ret
        end
      _ -> {:error, nil}
    end
  end
end
