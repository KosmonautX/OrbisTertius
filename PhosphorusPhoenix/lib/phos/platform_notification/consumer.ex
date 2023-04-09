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

  defp execute_event(%{spec: %{"type" => type, "entity" => entity, "entity_id" => id}} = store, from) do
    case decide_actor(entity, id) do
      {:ok, data} ->
        case send_notification(type, data, store) do
          data when data in [:ok, true] -> GenStage.reply(from, {store.id, :success})
          {:ok, _data} -> GenStage.reply(from, {store.id, :success})
          {:error, message} -> GenStage.reply(from, {store.id, :retry, message})
          _ -> GenStage.reply(from, {store.id, :retry})
        end
      err -> GenStage.reply(from, {store.id, :error, err})
    end
  end

  defp decide_actor("ORB", id) do
    case Phos.Action.get_orb(id) do
      {:ok, orb} -> {:ok, {orb.title, orb.initiator, orb.initiator, orb}}
      err -> err
    end
  end
  defp decide_actor("COMMENT", id) do
    case Phos.Comments.get_comment(id) do
      %Phos.Comments.Comment{} = comment -> 
        receiver = comment.orb |> Phos.Repo.preload(:initiator) |> Map.get(:initiator)
        {:ok, {comment.body, comment.initiator, receiver, comment}}
      err -> err
    end
  end

  defp send_notification(type, {body, sender, receiver, event}, %{spec: spec} = store) do
    condition = "'USR.#{store.recepient_id}' in topics"
    template = get_template(spec |> Map.get("options", %{}), store)
    data = Map.get(spec, "options", %{}) |> Map.get("data", %{})
    notification = PN.Template.parse(template, [sender: sender, receiver: receiver, event: event, body: body])
    case type do
      t when t in ["push", "broadcast"] -> send_broadcast_notification(template, [condition: condition, data: data])
      "email" -> # TODO: email integration
        :ok
      _ -> :error # not implemented yet
    end
  end

  defp send_broadcast_notification(template, options) do
    data = Keyword.get(options, :data, %{})
    condition = Keyword.get(options, :condition, %{})
    Fcmex.push("", notification: template, condition: condition, data: data)
  end

  defp get_token(%Phos.Users.User{} = user) do
    get_in(user, [Access.key(:integrations, %{}), Access.key(:fcm_token, nil)])
  end

  defp get_template(%{"notification" => notification}, _template), do: notification
  defp get_template(_, template), do: template
end
