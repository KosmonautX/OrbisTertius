defmodule Phos.PlatformNotification.Config.APNS do
  def gen do
    Sparrow.FCM.V1.APNS.new(
      %Sparrow.APNS.Notification{headers: [],
                                 alert_opts: [],
                                 aps_dictionary_opts: [],
                                 custom_data: []}
                                 #|> silent()
                                 |> Sparrow.APNS.Notification.add_badge(0)
                                 |> Sparrow.APNS.Notification.add_apns_priority("5")
                                 |> Sparrow.APNS.Notification.add_content_available(0),

      fn -> {"authorization", ""} end)
  end

  def silent(config) do
    config
    |> Sparrow.APNS.Notification.add_title("")
    |> Sparrow.APNS.Notification.add_body("")
    |> Sparrow.APNS.Notification.add_content_available(1)
  end

end
