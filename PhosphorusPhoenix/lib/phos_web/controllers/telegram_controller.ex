defmodule PhosWeb.TelegramController do
  use PhosWeb, :controller

  def create(conn, %{"hash" => hash, "id" => id} = params) do
    case valid_hash?(hash, Map.drop(params, ["hash"])) do
      true -> create_user(params)
        _ -> ExGram.send_message(id, "Error occured when receiving a callback", reply_markup: Phos.TeleBot.build_registration_button())
    end
    IO.inspect(params, pretty: true)
    render(conn, "index.html", %{success: true, telegram: Phos.OAuthStrategy.telegram()})
  end

  defp valid_hash?(challanger, params) do
    secret = :crypto.hash(:sha256, ExGram.Token.fetch())
    data =
      Enum.map(params, fn {k, v} -> k <> "=" <> v end)
      |> Enum.join("\n")

    :crypto.mac(:hmac, :sha256, secret, data)
    |> Base.encode16()
    |> String.downcase()
    |> String.equivalent?(challanger)
  end

  defp create_user(%{"id" => id} = params) do
    options =
      Map.merge(params, %{
        "sub" => id,
        "provider" => "telegram",
      })

    case Phos.Users.from_auth(options) do
      {:ok, _user} -> ExGram.send_message(id, "Registered successfully", reply_markup: Phos.TeleBot.build_menu_button())
      {:error, msg} -> ExGram.send_message(id, msg, reply_markup: Phos.TeleBot.build_menu_button())
    end
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
