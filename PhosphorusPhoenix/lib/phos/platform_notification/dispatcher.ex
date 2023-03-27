defmodule Phos.PlatformNotification.Dispatcher do
  use GenStage

  alias Phos.PlatformNotification, as: PN

  def start_link(state) do
    GenStage.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(_state) do
    {:producer_consumer, 0, subscribe_to: conn_opts()}
  end

  defp conn_opts do
    opts = Keyword.take(PN.config(), [:max_demand, :min_demand])
    [{PN.Producer, opts}]
  end

  def handle_events([event | _rest], from, state) do
    event
    |> filter_event()
    |> case do
      {:ok, data} ->
        GenStage.reply(from, :ok)
        {:noreply, [data], state + 1}
      _ -> 
        GenStage.reply(from, :error)
        {:noreply, [], state}
    end
  end
  def handle_events(_events, _from, state), do: {:noreply, [], state}

  defp filter_event({type, entity, id, msg}) when type in [:email, :push, :broadcast] do
    actor(entity, id)
    |> define_message(msg, type)
    |> case do
      {:filtered, _data} = data -> {:ok, data}
      err -> err
    end
  end
  defp filter_event(_data), do: :error

  defp actor("USR", id) do
    case Phos.Users.find_user_by_id(id) do
      {:ok, user} -> %{actor: user, token: get_token(user)}
      err -> err
    end
  end
  defp actor("ORB", id) do
    case Phos.Action.get_orb(id) do
      {:ok, orb} -> %{actor: orb, token: get_token(orb.initiator)}
      err -> err
    end
  end
  defp actor(_, _), do: :error

  defp get_token(%Phos.Users.User{} = user) do
    get_in(user, [Access.key(:integrations, %{}), Access.key(:fcm_token, nil)])
  end

  defp define_message(:error, _msg, _type), do: :error
  defp define_message({:error, _err_msg}, _msg, _type), do: :error
  defp define_message(result, msg_id, type) when is_list(result) do
    {:filtered, Enum.map(result, &find_message(&1, msg_id, type))}
  end
  defp define_message(result, msg_id, type), do: {:filtered, find_message(result, msg_id, type)}

  defp find_message(result, msg_id, type) do
    Map.merge(result, %{message: %{id: msg_id, content: "Lorem ipsum"}, type: type})
  end
end
