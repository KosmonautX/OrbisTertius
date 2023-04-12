defmodule Phos.PlatformNotification.Consumer.Fcm do
  use Phos.PlatformNotification.Specification

  @impl true
  def send(%{spec: spec} = store) do
    recipient = "'USR.#{store.recepient_id}' in topics"
    template = get_template(store)
    options = [notification: template, condition: recipient]

    case get_in(spec, [Access.key("options", %{}), "data"]) do
      data when is_map(data) -> Fcmex.push("", Keyword.put(options, :data, data))
      _ -> Fcmex.push("", options)
    end
  end

  defp get_template(%{spec: spec} = store) do
    spec
    |> get_in([Access.key("options", %{}), "notification"])
    |> case do
      n when is_map(n) -> n
      _ -> parse(store)
    end
  end

  def parse(%{template: template, spec: spec} = store) when not is_nil(template) do
    with {:ok, entity} <- get_actor(spec),
      sender <- Map.get(entity, :initiator),
      title <- Map.get(entity, :title),
      body <- Map.get(entity, :body, title) do
      parse(template, sender: sender.username, receiver: store.recepient.username, event: entity, body: body)
    end
  end
  def parse(_store), do: ""

  defp get_actor(%{"entity" => "ORB", "entity_id" => id}), do: Phos.Action.get_orb(id)
  defp get_actor(%{"entity" => "COMMENT", "entity_id" => id}) do
    Phos.Comments.get_comment!(id)
    |> Phos.Repo.preload([:initiator])
    |> case do
      %Phos.Comments.Comment{} = data -> {:ok, data}
      _ -> {:error, "Comment not found"}
    end
  end
  defp get_actor(_), do: nil
end
