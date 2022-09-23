defmodule PhosWeb.Menshen.Auth do
  import Joken.Config

  alias PhosWeb.Menshen.Role
  alias Phos.Users.{Private_Profile}

  def validate_user(token) do
    token
    |> String.split()
    |> List.last()
    |> Role.Pleb.verify_and_validate()
  end

  def validate_boni(token) do
    Role.Boni.verify_and_validate(token)
  end

  def generate_boni() do
    Role.Boni.generate_and_sign()
  end

  def generate_boni!(user_id) do
    {:ok, jwt, _claims} = Role.Boni.generate_and_sign(%{user_id: user_id})
    jwt
  end

  def generate_boni!() do
     {:ok, jwt, _claims} = Role.Boni.generate_and_sign(%{user_id: "Hanuman"})
     jwt
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
  defp parse_territories(%{private_profile: %Private_Profile{geolocation: geolocations}}) do
    Enum.reduce(geolocations, %{}, fn %{id: name, chronolock: chronolock, geohash: hash}, acc ->
      Map.put(acc, String.downcase(name), %{radius: chronolock, hash: hash})
    end)
  end


  defp parse_territories(_), do: %{}

end
