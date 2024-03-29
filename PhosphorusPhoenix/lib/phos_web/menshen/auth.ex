defmodule PhosWeb.Menshen.Auth do
  use Nebulex.Caching

  alias PhosWeb.Menshen.Role
  alias Phos.Users.{PrivateProfile}
  alias Phos.Cache

  def generate_user!(id, exp) when is_binary(id), do: generate_boni!(id, exp)
  def generate_user!(id) when is_binary(id) , do: generate_boni!(id)
  def generate_user!(_) , do: nil

  def validate_user(token) do
    token
    |> String.split()
    |> List.last()
    |> Role.Pleb.verify_and_validate()
  end

  def validate_fyr(token) do
    with {:ok, cert} <- get_cert(),
         {:ok, %{"kid" => kid}} <- Joken.peek_header(token),
         {:ok, keys} <- Map.fetch(JOSE.JWK.from_firebase(cert), kid),
         {:verify, {true, %{fields: %{"exp" => exp} = fields}, _}} <- {:verify, JOSE.JWT.verify(keys, token)},
         {:verify, {:ok, _}} <- {:verify, verify_expiry(exp)} do

      {:ok, fields}
    else

      {:verify, {:expired, _}} -> {:error, "Expired JWT"}

      _ -> {:error, "invalid token"}

    end

  end

  def validate_boni(token), do: Role.Boni.verify_and_validate(token)

  def generate_boni, do: Role.Boni.generate_and_sign()

  def generate_boni!(uid, exp) when is_binary(uid) do
    case Role.Boni.generate_and_sign(%{"user_id" => uid, "exp" => System.os_time(:second) + exp}) do
      {:ok, jwt, _claims} -> jwt
      _ -> nil
    end
  end

  def generate_boni!(uid) when is_binary(uid) do
    case Role.Boni.generate_and_sign(%{"user_id" => uid}) do
      {:ok, jwt, _claims} -> jwt
      _ -> nil
    end
  end

  def generate_boni!(_) do
    {:ok, jwt, _claims} = Role.Boni.generate_and_sign(%{"user_id" => "Hanuman"})
    jwt
  end

  def generate_boni!, do: Role.Boni.generate_and_sign!(%{"user_id" => "Hanuman"})


  def generate_user(user_id) do
    {:ok, user} = Phos.Users.find_user_by_id(user_id)
    %{"user_id"=> user.id,
      "fyr_id"=> user.fyr_id,
      "territory"=> parse_territories(user),
      "username"=> user.username}
    #|> Role.Boni.generate_claims
    |> Role.Pleb.generate_and_sign()
  end

  # geo utilities?
  defp parse_territories(%{private_profile: %PrivateProfile{geolocation: geolocations}}) do
    Enum.reduce(geolocations, %{}, fn %{id: name, chronolock: chronolock, geohash: hash}, acc ->
      Map.put(acc, String.downcase(name), %{radius: chronolock, hash: hash})
    end)
   end


  defp parse_territories(_), do: %{}

  # @decorate cacheable(cache: Cache,
  #   key: {Phos.External.GoogleCert, :get_cert},
  #   match: &cert_legit/1,
  #   opts: [ttl: &cert_expiry/1])

  defp get_cert() do
    case Cache.get({Phos.External.GoogleCert, :get_cert}) do
      nil ->
        case Phos.External.GoogleCert.get_cert() do
          {:ok, %{cert: cert, exp: ttl}} ->
            Cache.put({Phos.External.GoogleCert, :get_cert}, cert, ttl: ttl*1000)
          {:ok, cert}

          err -> {:error, err}
        end
      cert ->
        {:ok, cert}
    end
  end

  # defp cert_legit({:ok, _}), do: true
  # defp cert_legit(_), do: false

  defp verify_expiry(exp) do
    DateTime.utc_now()
    |> DateTime.to_unix()
    |> Kernel.<(exp)
    |> case do
      true -> {:ok, exp}
        _ -> {:expired, exp}
    end
  end
end
