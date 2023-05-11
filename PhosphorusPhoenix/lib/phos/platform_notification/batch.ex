defmodule Phos.PlatformNotification.Batch do
  def push(tokens, opts\\ [{:title, ""}, {:body, ""}])
  def push(%MapSet{} = tokens, opts), do: push(MapSet.to_list(tokens), opts)
  def push(tokens, [{:title, title} | [ {:body, body}| opts]]) when length(tokens) > 500 do
    Enum.chunk_every(tokens, 500)
    |> Enum.map(fn tokens ->
                 Sparrow.FCM.V1.Notification.new(:token, tokens, title, body,
                   Enum.into(opts, %{}))
               end)
    |> chunk_push()
  end

  def silent_push(%MapSet{} = tokens, opts), do: silent_push(MapSet.to_list(tokens), opts)
  def silent_push(tokens, opts) when length(tokens) > 500 do
    Enum.chunk_every(tokens, 500)
    |> Enum.map(fn tokens ->
                 Sparrow.FCM.V1.Notification.new(:token, tokens, "", "", Enum.into(opts, %{}))
    end)

    |> chunk_push()
  end

  def silent_push(tokens, opts) when length(tokens) <= 500 do
    Sparrow.FCM.V1.Notification.new(:token, tokens, "", "", Enum.into(opts, %{}))
    |> add_apns()
    |> Sparrow.API.push()
  end


  defp chunk_push(chunks) do
    chunks
    |> Enum.map(fn notif -> notif
               |> Sparrow.FCM.V1.Notification.add_apns(Phos.PlatformNotification.Config.APNS.gen())
               |> Sparrow.API.push() end)
  end

  defp add_apns(batch) do
    batch
    |> Sparrow.FCM.V1.Notification.add_apns(Phos.PlatformNotification.Config.APNS.gen())
  end
 end
