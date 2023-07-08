defmodule Phos.PlatformNotification.Consumer.Fcm do
  use Phos.PlatformNotification.Specification

  @impl true
  def send(%{recipient: %{integrations: %{fcm_token: _token}}} = store) do
    %{"body" => body, "title" => title} = get_template(store)
    data = get_data(store)

    # synchronous

    Sparrow.FCM.V1.Notification.new(:token, title, body,
      data
      |> Map.put(:title, title)
      |> Map.put(:body, body)
    )
    |> Sparrow.FCM.V1.Notification.add_apns(Phos.PlatformNotification.Config.APNS.gen())
    |> Sparrow.API.push()
    |> case do
      :ok -> {:ok, "Notification triggered"}
      err -> err
    end
  end

  def send({:file, path}) do
    Sparrow.FCM.V1.Notification.new(:file, path, nil, nil, nil)
    |> Sparrow.API.push()
    |> case do
      :ok -> {:ok, "Notification triggered"}
      err -> err
    end
  end

  def send(_), do: {:error, "No FCM Token"}

  def get_template(%{spec: %{"options" => %{"notification" => %{silent: true}}}}), do: %{title: "", body: ""}
  def get_template(%{spec: %{"options" => %{"notification" => notif}}}) when is_map(notif), do: notif
  def get_template(store), do: parse(store)


  def get_data(%{spec: %{"options" => %{"notification" => %{silent: true} = notif, "data" => data}}}) when is_map(data), do: Map.merge(data, notif)
  def get_data(%{spec: %{"options" => %{"data" => data}}}) when is_map(data), do: data
  def get_data(_store), do: %{}

  def parse(%{template: template, spec: spec} = store) when not is_nil(template) do
    with {:ok, entity} <- get_actor(spec),
      sender <- Map.get(entity, :initiator),
      title <- Map.get(entity, :title),
      body <- Map.get(entity, :body, title) do
      parse(template, sender: Map.get(sender, :username), receiver: store.recepient.username, event: entity, body: body)
    end
  end
  def parse(_store), do: ""

  defp get_actor(%{"entity" => "ORB", "entity_id" => id}), do: Phos.Action.get_orb(id)
  defp get_actor(%{"entity" => "COM", "entity_id" => id}) do
    Phos.Comments.get_comment!(id)
    |> Phos.Repo.preload([:initiator])
    |> case do
      %Phos.Comments.Comment{} = data -> {:ok, data}
      _ -> {:error, "Comment not found"}
    end
  end
  defp get_actor(_), do: %{}

  def send_notification_path() do
    project_id =
      Sparrow.PoolsWarden.choose_pool(:fcm)
      |> Sparrow.FCM.V1.ProjectIdBearer.get_project_id()

    "/v1/projects/#{project_id}/messages:send"
  end
end
