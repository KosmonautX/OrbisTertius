defmodule PhosWeb.Menshen.Auth do
  import Joken.Config

  alias PhosWeb.Menshen.Role

  def validate_user(token) do
    Role.Pleb.verify_and_validate(token)
  end

  def validate_boni(token) do
    Role.Boni.verify_and_validate(token)
  end

  def generate_boni() do
    Role.Boni.generate_and_sign()
  end

  def generate_user(user_id) do
    {:ok, user} = Phos.Users.find_user_by_id(user_id)
    %{user_id: user.fyr_id || user.id,
      territory: parse_territories(user),
      username: user.username}
    #|> Role.Boni.generate_claims
    |> Role.Boni.generate_and_sign()
  end

  # geo utilities?
  defp parse_territories(%{private_profile: %Phos.Users.Private_Profile{geolocation: geolocations}}) do
    Enum.reduce(geolocations, %{}, fn %{chronolock: chronolock, geohash: hash, location_description: desc}, acc ->
      Map.put(acc, String.downcase(desc), %{radius: chronolock, hash: :h3.to_string(hash)})
    end)
  end


  defp parse_territories(_), do: %{}

end
