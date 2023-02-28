defmodule PhosWeb.Menshen.Auth do
  use Nebulex.Caching

  alias PhosWeb.Menshen.Role
  alias Phos.Users.{Private_Profile}
  alias Phos.Cache

  def generate_user!(id), do: generate_boni!(id)

  def validate_user(token) do
    token
    |> String.split()
    |> List.last()
    |> Role.Pleb.verify_and_validate()
  end

  def validate_fyr(token) do
     with {:ok, body} <- get_cert(token),
         {:ok, %{"kid" => kid}} <- Joken.peek_header(token),
         {:ok, keys} <- Map.fetch(JOSE.JWK.from_firebase(body), kid),
         {:verify, {true, %{fields: %{"exp" => exp} = fields}, _}} <- {:verify, JOSE.JWT.verify(keys, token)},
         {:verify, {:ok, _}} <- {:verify, verify_expiry(exp)} do

      {:ok, fields}
    else

      {:verify, {:expired, _}} ->
        {:error, "Expired JWT"}

      {:verify, _} ->
      #in case of cycling of
        with {:ok, body} <- update_cert(token),
             {:ok, %{"kid" => kid}} <- Joken.peek_header(token),
             {:ok, keys} <- Map.fetch(JOSE.JWK.from_firebase(body), kid),
             {:verify, {true, %{fields: fields}, _}} <- {:verify, JOSE.JWT.verify(keys, token)} do

          {:ok, fields}
        else

          _ -> {:error, "invalid token"}

        end

      _ -> {:error, "invalid token"}
   end

  end

  def validate_boni(token), do: Role.Boni.verify_and_validate(token)

  def generate_boni, do: Role.Boni.generate_and_sign()

  def generate_boni!(user_id) do
    {:ok, jwt, _claims} = Role.Boni.generate_and_sign(%{user_id: user_id})
    jwt
  end

  def generate_boni!() do
     Role.Boni.generate_and_sign!(%{user_id: "Hanuman"})
  end

  def generate_user(user_id) do
    {:ok, user} = Phos.Users.find_user_by_id(user_id)
    %{user_id: user.id,
      fyr_id: user.fyr_id,
      territory: parse_territories(user),
      username: user.username}
    #|> Role.Boni.generate_claims
    |> Role.Pleb.generate_and_sign()
  end

  # geo utilities?
  defp parse_territories(%{private_profile: %Private_Profile{geolocation: geolocations}}) do
    Enum.reduce(geolocations, %{}, fn %{id: name, chronolock: chronolock, geohash: hash}, acc ->
      Map.put(acc, String.downcase(name), %{radius: chronolock, hash: hash})
    end)
   end


  defp parse_territories(_), do: %{}

  @decorate cacheable(cache: Cache, key: {Phos.External.GoogleCert, :get_cert})
  defp get_cert(token), do: Phos.External.GoogleCert.get_Cert()

  @decorate cache_put(
              cache: Cache,
              key: {Phos.External.GoogleCert, :get_cert},
              match: &cert_legit/1
            )
  defp update_cert(token), do: Phos.External.GoogleCert.get_Cert()


  defp cert_legit({:ok, _}), do: true
  defp cert_legit(_), do: false

  defp verify_expiry(exp) do
    cond do
      exp > DateTime.utc_now() |> DateTime.to_unix() -> {:ok, exp}
      true -> {:expired, exp}
    end
  end
end
