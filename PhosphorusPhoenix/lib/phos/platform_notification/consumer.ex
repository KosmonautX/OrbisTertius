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
        t when t in ["broadcast", "push"] -> {[data | fcm], mail}
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
      {:ok, _result} -> GenStage.reply(from, {store.id, :success})
      {:error, msg} -> GenStage.reply(from, {store.id, :error, msg})
      err -> GenStage.reply(from, {store.id, :unknown_error, err})
    end

    execute_mail_events(tail, from)
  end

  defp execute_fcm_events(data, from) do
    data
    |> create_fcm_spec()
    |> filter_user_token(from)
    |> write_temp_file()
    |> send_to_client(from)
  end

  defp create_fcm_spec(data) do
    Enum.reduce(data, {[], [], []}, fn d, {succeed_data, succeed_ids, failed_ids} -> 
      message = %{
        notification: __MODULE__.Fcm.get_template(d),
        data: __MODULE__.Fcm.get_data(d)
      }

      case decide_recipient(message, d) do
        {:ok, msg} -> {[msg | succeed_data], [d.id | succeed_ids], failed_ids}
        {:error, _} -> {succeed_data, succeed_ids, [d.id | failed_ids]}
      end
    end)
  end

  defp filter_user_token({succeed_data, succeed_ids, failed_ids}, from) do
    path = __MODULE__.Fcm.send_notification_path()

    spawn(fn -> GenStage.reply(from, {failed_ids, :errors, "User doesn't have FCM Token"}) end)

    {Enum.map(succeed_data, fn data ->
      Enum.join(basic_data(path), "\n")
      |> Kernel.<>("\n")
      |> Kernel.<>(%{message: data} |> Jason.encode!())
      |> Kernel.<>("\n")
    end)
    |> Enum.join("\n")
    |> Kernel.<>("\n\n")
    |> Kernel.<>("--subrequest_boundary--"), succeed_ids}
  end

  defp write_temp_file({binary, ids}) when length(ids) > 0 do
    path = :os.cmd('mktemp') |> to_string() |> String.replace_suffix("\n", "")
    case File.write(path, binary) do
      :ok -> {:ok, {path, ids}}
      err -> err
    end
  end
  defp write_temp_file(_), do: "File not generated"

  defp send_to_client({:ok, {path, ids}}, from) do
    case __MODULE__.Fcm.send({:file, path}) do
      {:ok, _result} ->
        _ = File.rm(path)
        GenStage.reply(from, {ids, :success})
      err -> GenStage.reply(from, {nil, :unknown_error, err})
    end
  end
  defp send_to_client(err, from), do: GenStage.reply(from, {nil, :file_error, err})

  defp decide_recipient(message, %{recipient: %{integrations: %{fcm_token: token}}}) when not is_nil(token) do
    {:ok, Map.put(message, :token, token)}
  end
  defp decide_recipient(_message, _recipient), do: {:error, "User doesn't have FCM Token"}

  defp basic_data(path) do
    [
      "--subrequest_boundary",
      "Content-Type: application/http",
      "Content-Transfer-Encoding: binary",
      "",
      "POST #{path}",
      "Content-Type: application/json",
      "Accept: application/json",
      ""
    ]
  end
end
