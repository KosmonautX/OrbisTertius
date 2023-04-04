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
  defp execute_events([event | tail], from) do
    case PN.Store.get(event) do
      %PN.Store{} = event -> execute_event(event, from)
      _ -> :not_found
    end

    execute_events(tail, from)
  end

  defp execute_event(%{spec: {type, entity, id, template_id}} = store, from) do
    case decide_actor(entity, id) do
      {:ok, {_body, _sender, _receiver, _event, _count} = data} ->
        case send_notification(type, data, template_id) do
          data when data in [:ok, true] -> GenStage.reply(from, {store.id, :success})
          {:ok, _data} -> GenStage.reply(from, {store.id, :success})
          {:error, message} -> GenStage.reply(from, {store.id, :retry, message})
          _ -> GenStage.reply(from, {store.id, :retry})
        end
      err -> GenStage.reply(from, {store.id, :error, err})
    end
  end

  defp decide_actor("USR", id) do
    case Phos.Users.find_user_by_id(id) do
      {:ok, user}  -> {:ok, {"", user, user, nil, nil}}
      err -> err
    end
  end
  defp decide_actor("ORB", id) do
    case Phos.Action.get_orb(id) do
      {:ok, orb} -> {:ok, {orb.title, orb.initiator, orb.initiator, orb, 0}}
      err -> err
    end
  end
  defp decide_actor("COMMENT", id) do
    case Phos.Comments.get_comment(id) do
      %Phos.Comments.Comment{} = comment -> 
        receiver = comment.orb |> Phos.Repo.preload(:initiator) |> Map.get(:initiator)
        {:ok, {comment.body, comment.initiator, receiver, comment, 0}}
      err -> err
    end
  end

  defp send_notification(type, {body, sender, receiver, event, count}, template_id) do
    template = PN.Template.parse(template_id, [sender: sender, receiver: receiver, event: event, count: count, body: body])
    case type do
      t when t in [:push, :broadcast] -> send_from_fcm(template, get_token(receiver))
      :email -> # TODO: email integration
        :ok
    end
  end

  defp send_from_fcm(_template, nil), do: {:error, "FCM token not found"}
  defp send_from_fcm(template, token) do
    Fcmex.push(token, notification: template)
  end

  defp get_token(%Phos.Users.User{} = user) do
    get_in(user, [Access.key(:integrations, %{}), Access.key(:fcm_token, nil)])
  end
end
