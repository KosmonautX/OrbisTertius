defmodule Phos.TeleBot.ProfileFSM do
  defstruct [:telegram_id, :state, data: %{return_to: ""}, path: "self/update", metadata: %{message_id: ""}]
  alias Phos.TeleBot.{StateManager}
  alias Phos.TeleBot.Core, as: BotCore
  alias Phos.TeleBot.Components.{Button, Template}

  ## routing of state
  def update_user_location(telegram_id, geo, desc) do
    with {:ok, %{branch: %{data: %{location_type: type}}}} <- StateManager.get_state(telegram_id) do
      validate_user_update_location(type, telegram_id, geo, desc)
    else
       err -> BotCore.error_fallback(telegram_id, err)
    end
  end

  defp validate_user_update_location(nil, telegram_id, _, _), do: ExGram.send_message(telegram_id, "You must set your location type")
  defp validate_user_update_location(type, telegram_id, geo, desc) do
    {:ok, %{private_profile: priv} = user} = BotCore.get_user_by_telegram(telegram_id)
    geos = case priv do
      nil ->
        []
      _ ->
        Map.get(priv, :geolocation, []) |> Enum.map(&Map.from_struct(&1) |> Enum.reduce(%{}, fn {k, v}, acc ->
          Map.put(acc, to_string(k), v) end)) |> Enum.reduce([], fn loc, acc ->
            case Map.get(loc, "id") == type do
              true -> acc
              _ -> [loc | acc]
            end
          end)
    end
    present_territory = geos
      |> Enum.map(fn loc -> :h3.parent(loc["geohash"], 11) end)
      |> Enum.map(fn hash -> :h3.parent(hash, 8) |> :h3.k_ring(1) end)
      |>  List.flatten() |> Enum.uniq()
    places = geos
      |> Enum.map(fn loc ->
        hash = :h3.parent(loc["geohash"], 8)
        %{"geohash" => hash,
          "id" => loc["id"],
          "location_description" => hash |> Phos.Mainland.World.locate()}
      end)
      |> Enum.reject(fn loc -> loc["id"] == "live" end)
    params = %{
      "private_profile" => %{"user_id" => user.id,
        "geolocation" => [%{"id" => type,
        "geohash" => :h3.from_geo(geo, 11),
        "location_description" => desc} | geos]},
      "public_profile" => %{"territories" => present_territory, "places" => places},
      "personal_orb" => %{
        "id" => (if is_nil(user.personal_orb), do: Ecto.UUID.generate(), else: user.personal_orb.id),
        "active" => true,
        "userbound" => true,
        "initiator_id" => user.id,
        "locations" =>  present_territory |> Enum.map(fn hash -> %{"id" => hash} end)
      }
    }

    case Phos.Users.update_territorial_user(user, params) do
      {:ok, user} ->
        user
      _ -> ExGram.send_message(telegram_id, "Your #{type} location is not set.", reply_markup: Button.build_menu_inlinekeyboard())
    end
  end
end
