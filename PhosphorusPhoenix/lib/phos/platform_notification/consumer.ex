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
    {firebase, mail} = events
    |> Enum.reduce({[], []}, fn %{spec: spec} = data, {fcm, mail} = acc ->
      Map.get(spec, "type")
      |> case do
        t when t in ["broadcast", "push"] ->
             {[data | fcm], mail}
        "email" -> {fcm, [data | mail]}
        _ -> acc
      end
    end)

    spawn(fn -> execute_mail_events(mail, from) end)
    spawn(fn -> execute_fcm_events(firebase, from) end)

    {:noreply, [], state}
  end

  defp execute_mail_events([], _from), do: :ok
  defp execute_mail_events([store | tail], from) do
    case __MODULE__.Email.send(store) do
      {:ok, _result} -> 
        _ = write_log(:info, "success send notification from email", nil)
        GenStage.reply(from, {store.id, :success})
      {:error, msg} ->
        _ = write_log(:warning, "failed sending notification from email", msg)
        GenStage.reply(from, {store.id, :error, msg})
      err ->
        _ = write_log(:warning, "error sending notification from email", err)
        GenStage.reply(from, {store.id, :unknown_error, err})
    end

    execute_mail_events(tail, from)
  end

  defp execute_fcm_events(data, from) do
    data
    |> create_fcm_spec()
    |> Enum.each(&send_to_client(&1, from))
  end

  defp create_fcm_spec(data) do
    Enum.reduce(data, %{}, fn d, acc ->
      message = __MODULE__.Fcm.get_template(d)
      body    = get_in(message, [Access.key(:body, "")])
      title   = get_in(message, [Access.key(:title, "")])
      token   = get_in(d, [Access.key(:recipient, %{}), Access.key(:integrations, %{}), Access.key(:fcm_token, "")])
      data    = __MODULE__.Fcm.get_data(d)

      Sparrow.FCM.V1.Notification.new(:token, token, title, body, data)
      |> Sparrow.FCM.V1.Notification.add_apns(Phos.PlatformNotification.Config.APNS.gen())
      |> then(fn n ->
        Map.put(acc, d.id, n)
      end)
    end)
  end

  defp send_to_client({id, notif}, from) do
    Sparrow.API.push(notif)
    |> handle_result(id, from)
  end

  defp handle_result(:ok, id, from) do
    _ = write_log(:info, "success sending notification", nil)
    _ = GenStage.reply(from, {id, :success})
  end

  defp handle_result(err, id, from) do
    _ = write_log(:warning, "error sending notification", err)
    _ = GenStage.reply(from, {id, :error})
  end

  defp write_log(type, msg, error) do
    apply(:logger, type, [%{
      label: {Phos.PlatformNotification.Consumer, msg},
      report: %{
        module: __MODULE__,
        executor: __MODULE__.Fcm,
        error_message: error
      }
    }, %{
        domain: [:phos, :platform_notification],
        error_logger: %{tag: type}
      }
    ])
  end
end
