defmodule PhosWeb.TelegramController do
  use PhosWeb, :controller

  # DEPRECATED. Use create_user
  # def create(conn, %{"hash" => hash, "id" => id} = params) do
  #   case valid_hash?(hash, Map.drop(params, ["hash"])) do
  #     true -> create_user(params)
  #       _ -> ExGram.send_message(id, "Error occured when receiving a callback", reply_markup: Phos.TeleBot.build_registration_button())
  #   end
  #   IO.inspect(params, pretty: true)
  #   render(conn, :home, %{success: true, telegram: Phos.OAuthStrategy.telegram()})
  # end

  # defp valid_hash?(challanger, params) do
  #   secret = :crypto.hash(:sha256, ExGram.Token.fetch())
  #   data =
  #     Enum.map(params, fn {k, v} -> k <> "=" <> v end)
  #     |> Enum.join("\n")

  #   :crypto.mac(:hmac, :sha256, secret, data)
  #   |> Base.encode16()
  #   |> String.downcase()
  #   |> String.equivalent?(challanger)
  # end

  def webhook(conn, _params) do
    case parse_update(conn.body_params) do
      {:ok, update} ->
          # context = %ExGram.Cnt{
          #   update: update
          # }
          # |> Map.put(:fsm, %Phos.TeleBot{state: "home", data: nil})
        Phos.TeleBot.handle(update)
        send_resp(conn, 200, "OK")
      {:error, reason} ->
        send_response(reason, conn, 400)
    end
  end

  defp parse_update(body_params) do
  # require IEx; IEx.pry()
    case body_params do
      %{"message" => %{"location" => location} = message} ->
        {:ok, {:location, message}}
      %{"message" => %{"photo" => photo} = message} ->
        {:ok, {:photo, message}}
      %{"message" => %{"sticker" => sticker} = message} ->
        {:ok, {:sticker, message}}
      %{"message" => %{"document" => document} = message} ->
        {:ok, {:document, document}}
      %{"message" => message} ->
        {:ok, {:message, extract_command(message), message}}
      %{"callback_query" => query} ->
        {:ok, {:callback_query, query}}
      %{"inline_query" => query} ->
        {:ok, {:inline_query, query}}
      _ ->
        {:error, "Invalid update payload"}
    end
  end

  # TODO: refactor this and tidy so that we don't have to explicitly edit this codeblock when adding new commands
  def extract_command(%{"text" => text}) do
    case String.trim(text) do
      "/start" -> :start
      "/menu" -> :menu
      "/help" -> :help
      "/register" -> :register
      "/post" -> :post
      "/profile" -> :profile
      _ -> :text
    end
  end

  defp send_response(response, conn, status) do
    conn
    |> put_status(status)
    |> put_resp_content_type("application/json")
    |> send_resp(status, response)
  end
end

# %{
#   "auth_date" => "1668750364",
#   "first_name" => "Satrio",
#   "hash" => "cc1560d1c98e4f87365dc50884dc3e70677f4a54ab6faf97fee30c0aa1be73d2",
#   "id" => "955679854",
#   "last_name" => "Nugroho",
#   "photo_url" => "https://t.me/i/userpic/320/STowcwXVguYL-0yyTF__7Bnp8weYA_8QiW9nPIQngV4.jpg",
#   "username" => "satrionugrohosn"
# }
