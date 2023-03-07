defmodule Phos.External.TelegramClient do
  use HTTPoison.Base

  def report(user= %Phos.Users.User{}, report) do
    send_message("-1001258902545",
      """
      Report was sent in by <a href="https://app.scrb.ac/?apn=com.scratchbac.baladi&ibi=com.baladi.scratchbac&isi=1587462661&link=https%3A%2F%2Fapp.scrb.ac%2Fuserland%2Fusers%2F#{user.id}"><b>#{user.username}</b></a>!
      Metadata:
      """ <>
     case report["archetype"] do
       "USR" ->
         """
         Reported <b>User ID</b>: <a href="https://app.scrb.ac/?apn=com.scratchbac.baladi&ibi=com.baladi.scratchbac&isi=1587462661&link=https%3A%2F%2Fapp.scrb.ac%2Fuserland%2Fusers%2F#{report["id"]}">#{report["id"]}</a>
         """
       "ORB" ->
         """
         Reported <b>Orb UUID</b>: <a href="https://app.scrb.ac/?apn=com.scratchbac.baladi&ibi=com.baladi.scratchbac&isi=1587462661&link=https%3A%2F%2Fapp.scrb.ac%2Forbland%2Forbs%2F#{report["id"]}">#{report["id"]}</a>
         """
     end
      <> "Why? "
      <> (report["message"] |> Enum.join(", ")))
   end



  defp send_message(chat_id, message) do
    {:ok, _resp = %HTTPoison.Response{}} = get(
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
