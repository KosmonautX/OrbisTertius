defmodule Phos.PlatformNotification.Consumer.Fcm do
  use Phos.PlatformNotification.Specification

  @impl true
  def send(%{spec: spec} = store) do
    recepient = "'USR.#{store.recepient_id}' in topics"
    %{body: body, title: title} = get_template(store)
    link = get_link(store)

    android =
      Sparrow.FCM.V1.Android.new()
      |> Sparrow.FCM.V1.Android.add_title(title)
      |> Sparrow.FCM.V1.Android.add_body(body)

    webpush =
      Sparrow.FCM.V1.Webpush.new(link)
      |> Sparrow.FCM.V1.Webpush.add_title(title)
      |> Sparrow.FCM.V1.Webpush.add_body(body)

    Sparrow.FCM.V1.Notification.new(:topic, recepient)
    |> Sparrow.FCM.V1.Notification.add_android(android)
    |> Sparrow.FCM.V1.Notification.add_webpush(webpush)
    |> Sparrow.API.push()
  end

  defp get_template(%{spec: spec} = store) do
    spec
    |> get_in([Access.key("options", %{}), "notification"])
    |> case do
      n when is_map(n) -> n
      _ -> parse(store)
    end
  end

  defp get_link(%{spec: spec} = store) do
    spec
    |> get_in([Access.key("options", %{}), Access.key("data", %{}), "action_path"])
    |> case do
      nil -> Map.get(store.template, :click_action)
      l -> l
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
