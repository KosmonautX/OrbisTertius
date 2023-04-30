defmodule Phos.PlatformNotification.Consumer.Fcm do
  use Phos.PlatformNotification.Specification

  @impl true
  def send(%{recipient: %{integrations: %{fcm_token: token}}} = store) do
    IO.inspect "#{store.recipient.username} << #{get_in(store.spec, ["options", "notification", "title"])}"
    #recipient = "'USR.#{store.recipient_id}' in topics"
    %{"body" => body, "title" => title} = get_template(store)
    data = get_data(store)

    # synchronous

    Sparrow.FCM.V1.Notification.new(:token, token, title, body, data)
    |> Sparrow.API.push()
    |> case do
      :ok -> {:ok, "Notification triggered"}
      err -> err
    end
    # Fcmex.push("", notification: %{title: title, body: body} ,condition: recipient, data: data)
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

  def get_template(%{spec: spec} = store) do
    spec
    |> get_in([Access.key("options", %{}), "notification"])
    |> case do
      n when is_map(n) -> n
      _ -> parse(store)
    end
  end

  def get_data(%{spec: spec} = _store) do
    spec
    |> get_in([Access.key("options", %{}), Access.key("data", %{})])
    |> case do
      nil -> %{}
      l -> l
    end
  end

  # defp get_link(%{spec: spec} = store) do
  #   spec
  #   |> get_in([Access.key("options", %{}), Access.key("data", %{}), "action_path"])
  #   |> case do
  #     nil -> Map.get(store.template, :click_action)
  #     l -> l
  #   end
  # end

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
