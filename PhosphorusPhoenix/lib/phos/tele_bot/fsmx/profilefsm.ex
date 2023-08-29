defmodule Phos.TeleBot.ProfileFSM do
  defstruct [:telegram_id, :state, data: %{return_to: ""}, path: "self/update", metadata: %{message_id: ""}]
  alias Phos.TeleBot.{StateManager}
  alias Phos.TeleBot.Core, as: BotCore
  alias PhosWeb.Util.Geographer

  ## routing of state
  def update_user_location(telegram_id, latlon, desc) do
    with {:ok, %{id: user_id, private_profile: private_profile}} <- BotCore.get_user_by_telegram(telegram_id),
         {:ok, %{branch: %{data: %{location_type: type}}}} <- StateManager.get_state(telegram_id) do
      geolocation =
        case private_profile do
          nil ->
            []
          _ ->
              Enum.map(private_profile.geolocation, fn loc ->
                Map.from_struct(loc)
                |> Map.delete(:chronolock)
              end)
        end
      geolocation =
        Enum.map(geolocation, &({&1.id,
          Enum.map(&1, fn {k, v} -> {to_string(k), v} end)
          |> Enum.into(%{})}))
        |> Enum.into(%{})
      updated_geolocation =
        Map.put(geolocation, type, %{"id" => type, "geohash" => :h3.from_geo(latlon, 11), "location_description" => desc})
        |> Map.values()
      {:ok, user} = Geographer.update_territory(user_id, updated_geolocation)
      {:ok, %{user | tele_id: telegram_id}}
    else
       err -> {:error, err}
    end
  end
end
