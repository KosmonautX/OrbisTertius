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
      {:ok, result} -> 
        :logger.info(%{
          label: {Phos.PlatformNotification.Consumer, "success send notification from email"},
          report: %{
            module: __MODULE__,
            executor: __MODULE__.Email,
            data: result,
          }
        }, %{
          domain: [:phos, :platform_notification],
          error_logger: %{tag: :info_msg}
        })
        GenStage.reply(from, {store.id, :success})
      {:error, msg} ->
        :logger.info(%{
          label: {Phos.PlatformNotification.Consumer, "failed sent notification from email"},
          report: %{
            module: __MODULE__,
            executor: __MODULE__.Email,
            message: msg,
          }
        }, %{
          domain: [:phos, :platform_notification],
          error_logger: %{tag: :info_msg}
        })
        GenStage.reply(from, {store.id, :error, msg})
      err ->
        :logger.info(%{
          label: {Phos.PlatformNotification.Consumer, "error sent notification from email"},
          report: %{
            module: __MODULE__,
            executor: __MODULE__.Email,
            message: err
          }
        }, %{
          domain: [:phos, :platform_notification],
          error_logger: %{tag: :info_msg}
        })
        GenStage.reply(from, {store.id, :unknown_error, err})
    end

    execute_mail_events(tail, from)
  end

  defp execute_fcm_events(data, from) do
    IO.inspect(data, label: "fcm")
    data
    |> create_fcm_spec()
    |> filter_user_token(from)
    |> send_to_client(from)
  end

  defp create_fcm_spec(data) do
    Enum.reduce(data, {[], [], []}, fn d, {succeed_data, succeed_ids, failed_ids} ->
      message = __MODULE__.Fcm.get_template(d)
      IO.inspect(message, label: "message")
      data = __MODULE__.Fcm.get_data(d)

      case decide_recipient(message, data, d) do
        {:ok, msg} -> {[msg | succeed_data], [d.id | succeed_ids], failed_ids}
        {:error, _} -> {succeed_data, succeed_ids, [d.id | failed_ids]}
      end
    end)
  end

  defp filter_user_token({succeed_data, succeed_ids, failed_ids}, from) when length(failed_ids) > 0 do
    spawn(fn -> GenStage.reply(from, {failed_ids, :errors, "User doesn't have FCM Token"}) end)
    {succeed_data, succeed_ids}
  end

  defp filter_user_token({succeed_data, succeed_ids, _failed_ids}, _from) do
    {succeed_data, succeed_ids}
  end

  defp send_to_client({[%Sparrow.FCM.V1.Notification{} | _] = notifs, ids}, from) do
    IO.inspect(notifs, label: "Notification Sending")
    case Sparrow.API.push(notifs) do
      :ok ->
        :logger.info(%{
          label: {Phos.PlatformNotification.Consumer, "success batching notification to fcm"},
          report: %{
            module: __MODULE__,
            executor: __MODULE__.Fcm,
            succeed_data: ids,
          }
        }, %{
          domain: [:phos, :platform_notification],
          error_logger: %{tag: :info_msg}
        })
        GenStage.reply(from, {ids, :success})
      err ->
        :logger.warning(%{
          label: {Phos.PlatformNotification.Consumer, "error batching notification to fcm"},
          report: %{
            module: __MODULE__,
            executor: __MODULE__.Fcm,
            error_message: err
          }
        }, %{
          domain: [:phos, :platform_notification],
          error_logger: %{tag: :warning_msg}
        })
        GenStage.reply(from, {nil, :unknown_error, err})
    end
  end
  defp send_to_client(err, from), do: GenStage.reply(from, {nil, :file_error, err})

  defp decide_recipient(%{title: title} = msg, data, %{recipient: %{integrations: %{fcm_token: token}}}) when not is_nil(token) do
    {:ok, Sparrow.FCM.V1.Notification.new(:token, token, title, get_in(msg, [:body]) || "", data)
    |> Sparrow.FCM.V1.Notification.add_apns(Phos.PlatformNotification.Config.APNS.gen())}
  end

  defp decide_recipient(_message, _data, _recipient), do: {:error, "User doesn't have FCM Token"}

end
