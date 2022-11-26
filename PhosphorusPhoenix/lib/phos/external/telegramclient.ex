defmodule Phos.External.TelegramClient do
  use HTTPoison.Base

  def report(user= %Phos.Users.User{}, report) do
    send_message("-1001258902545",
      "Report was sent in by <b>#{user.username}</b>!
      Metadata:
      " <>
     case report.archetype do
       "USR" ->
         "Reported <b>User ID</b>: <code> #{report.id}</code>"

       "ORB" ->
         "Reported <b>Orb UUID</b>: <code> #{report.id}</code>"
     end
     <> (report.message |> Enum.join(",")))
   end



  defp send_message(chat_id, message) do
    {:ok, resp = %HTTPoison.Response{}} = get(
      "sendMessage"
      |> URI.parse()
      |> Map.put(:query,
      URI.encode_query(%{
            chat_id: chat_id,
            parse_mode: "HTML",
            text: message
                       }))
                       |> URI.to_string())
  end

  ## Full API Documentation

  def process_request_url(url) do
    "https://api.telegram.org/bot#{System.get_env("TELEGRAM_BOT_ID")}/" <> url
  end

  def process_response_body(body), do: body |> Jason.decode!()

  def process_request_body(body) when is_map(body), do: Jason.encode!(body)
  def process_request_body(body) , do: body

end
