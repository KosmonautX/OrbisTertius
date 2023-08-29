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
    _ -> {:error, :unknown}
    end
  end

  defp do_get_user_profile(id) do
    retry with: constant_backoff(100) |> Stream.take(5) do
      Phos.External.HeimdallrClient.get("/tele/get_users/" <> id)
    after
      {:ok, _result} = response -> response
    else
      err ->
        err
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

  defp insert_or_update_user(%{"kind" => "identitytoolkit#GetAccountInfoResponse", "users" => user_info }) do
    # https://developers.google.com/resources/api-libraries/documentation/identitytoolkit/v3/python/latest/identitytoolkit_v3.relyingparty.html#getAccountInfo
    data = List.first(user_info)
    Multi.new()
    |> Multi.run(:providers, fn _repo, _ -> {:ok, Map.get(data, "providerUserInfo")} end)
    |> Multi.run(:email, fn _repo, _ -> {:ok, Map.get(data, "email")} end)
    |> Multi.run(:payload, fn _repo, %{providers: providers, email: email} ->
      {:ok, %{"fyr_id" => data["localId"], "email" => email_provider(providers) || email}} end)
    |> Multi.run(:user, &cast_fyr_user(&1, &2, data))
    |> Multi.insert_all(:registered_providers, Users.Auth, &insert_with_provider/1, on_conflict: :replace_all, conflict_target: [:user_id, :auth_id, :auth_provider])
    |> Phos.Repo.transaction()
    |> case do
      {:ok, data} -> data
      {:error, err} -> err
      {:error, name, fields, required} -> %{name: name, fields: fields, required: required}
    end
  end

  defp cast_fyr_user(_repo, %{payload: %{"email" => email} = payload}, data) when is_binary(email) do
    case Users.get_user_by_email(email) do
      %Users.User{fyr_id: nil} = user ->
        user
        |> Users.User.fyr_registration_changeset(%{fyr_id: data["localId"]})
        |> Phos.Repo.update()

      %Users.User{} = user -> {:ok, user}
      nil -> 
        Users.get_user_by_fyr(data["localId"])
        |> cast_nil_user_by_fyr(payload)
    end
  end
  defp cast_fyr_user(_repo, %{payload: %{"fyr_id" => fyr_id} = payload}, _data) do
    case Users.get_user_by_fyr(fyr_id) do
      %Users.User{} = user -> {:ok, user}
      nil -> Users.create_user(payload)
    end
  end

  defp email_provider(providers) when length(providers) > 0 do
    providers
    |> List.first()
    |> Map.get("email", nil)
  end
  defp email_provider(_), do: nil

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

  defp cast_nil_user_by_fyr(%Users.User{} = user, %{"email" => email}) do
    user
    |> Users.User.changeset(%{email: email})
    |> Phos.Repo.update()
  end
  defp cast_nil_user_by_fyr(_, payload), do: Users.create_user(payload)
end
