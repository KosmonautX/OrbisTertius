defmodule PhosWeb.Util.Migrator do
  @moduledoc """

  For our Migration Utility functions that transform data from our Heimdallr APIs to our internal data models

  """

  use Retry

  alias Phos.Users
  alias Ecto.Multi

  def user_profile(id) do
    with {:ok, response} <- do_get_user_profile(id),
         true <- response.status_code >= 200 and response.status_code < 300,
         users <- user_migration(response.body, id) do
      {:ok, users}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp do_get_user_profile(id) do
    retry with: constant_backoff(100) |> Stream.take(5) do
      Phos.External.HeimdallrClient.get("/tele/get_users/" <> id)
    after
      {:ok, _result} = response -> response
    else
      err -> err
    end
  end

  def fyr_profile(token) do
    with {:ok, response} <- do_get_account_info(token),
         true <- response.status_code >= 200 and response.status_code < 300,
         users <- insert_or_update_user(response.body) do
      {:ok, users}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp do_get_account_info(token) do
    retry with: constant_backoff(100) |> Stream.take(5) do
      Phos.External.GoogleIdentity.post("getAccountInfo", %{idToken: token})
    after
      {:ok, _result} = response -> response
    else
      error -> error
    end
  end

  defp user_migration(response, id) when is_list(response) do
    Enum.map(response, &user_migration(&1, id))
    |> Task.await_many()
    |> Enum.map(&(&1.user))
    |> Enum.map(&Phos.Repo.preload(&1, [:auths]))
  end

  defp user_migration(response, id) when is_map(response) do
    Task.async(fn ->
      insert_or_update_user(response, id)
    end)
  end

  defp insert_or_update_user(%{"kind" => "identitytoolkit#GetAccountInfoResponse", "users" => user_info }) do
    # https://developers.google.com/resources/api-libraries/documentation/identitytoolkit/v3/python/latest/identitytoolkit_v3.relyingparty.html#getAccountInfo
    data = List.first(user_info)
    Multi.new()
    |> Multi.run(:providers, fn _repo, _ -> {:ok, Map.get(data, "providerUserInfo")} end)
    |> Multi.run(:payload, fn _repo, %{providers: providers} ->
      {:ok, %{"fyr_id" => data["localId"], "email" => email_provider(providers)}}
    end)
    |> Multi.run(:user, fn _repo, %{payload: payload} ->
      case Users.get_user_by_fyr(data["localId"]) do
        %Users.User{} = user -> {:ok, user}
        nil ->
          Users.create_user(payload)
      end
    end)
    |> Multi.insert_all(:registered_providers, Users.Auth, &insert_with_provider/1, on_conflict: :replace_all, conflict_target: [:auth_id, :user_id, :auth_provider])
    |> Phos.Repo.transaction()
    |> case do
      {:ok, data} -> data
      {:error, err} -> err
      {:error, name, fields, required} -> %{name: name, fields: fields, required: required}
    end
  end


  defp insert_or_update_user(data, id) do
    Multi.new()
    |> Multi.run(:providers, fn _repo, _ -> {:ok, Map.get(data, "providerData")} end)
    |> Multi.run(:geolocation, fn _repo, _ -> {:ok, Map.get(data, "geolocation")} end)
    |> Multi.run(:payload, fn _repo, %{geolocation: locations, providers: providers} ->
      {:ok,
        Map.get(data, "payload")
        |> Map.put("fyr_id", id)
        |> Map.put("email", email_provider(providers))
        |> Map.put("public_profile", %{
          "birthday" => get_in(data, ["payload", "birthday"]),
          "bio" => get_in(data, ["payload", "bio"])
        })
        |> Map.put("private_profile", %{
          "geolocation" => parse_geolocation(locations)
        })
      }
    end)
    |> Multi.run(:user, fn _repo, %{payload: payload} ->
      case Users.get_user_by_fyr(id) do
        %Users.User{} = user -> {:ok, user}
        nil ->
          Users.create_user(payload)
      end
    end)
    |> Multi.insert_all(:registered_providers, Users.Auth, &insert_with_provider/1, on_conflict: :replace_all, conflict_target: [:auth_id, :user_id, :auth_provider])
    |> Phos.Repo.transaction()
    |> case do
      {:ok, data} -> data
      {:error, err} -> err
      {:error, _name, changeset, _required} -> {:error, changeset}
    end
  end

  defp email_provider(providers) when length(providers) > 0 do
    providers
    |> List.first()
    |> Map.get("email", "")
  end
  defp email_provider(_), do: ""

  defp parse_geolocation(locations) when map_size(locations) > 0 do
    locations
    |> Enum.reduce([], fn {k, v}, acc -> [ Map.put(v, "id", k) | acc] end)
    |> Enum.map(&get_location_from_h3/1)
  end
  defp parse_geolocation(_), do: []

  defp get_location_from_h3(%{"geohashing" => %{"hash" => hash}} = data) do
    geo =
      hash
      |> to_charlist()
      |> :h3.from_string()

    Map.put(data, "geohash", geo)
  end


  defp get_location_from_h3(data), do: data

  defp insert_with_provider(%{providers: providers, user: user}) when length(providers) > 0 do
    time = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    providers
    |> Enum.map(fn provider ->
      %{
        auth_id: get_in(provider, ["uid"]) || get_in(provider, ["rawId"]),
        user_id: user.id,
        auth_provider: Map.get(provider, "providerId", "") |> String.split(".") |> List.first(),
        inserted_at: time,
        updated_at: time
      }
    end)
    |> Enum.reject(fn %{auth_provider: prov, auth_id: id} ->
      is_nil(id) or prov == "password"
    end)
  end

  defp insert_with_provider(_), do: []

end
