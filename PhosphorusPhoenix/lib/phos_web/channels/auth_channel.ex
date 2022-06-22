defmodule PhosWeb.AuthChannel do
  use PhosWeb, :channel

  def join("auth:usr:" <> id, _payload, socket) when id != "" do
    if authorized?(socket, id) do
      send(self(), :renew_token)
      {:ok, assign(socket, :user_id,  id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end
  def join(_, _payload, socket), do: {:error, %{reason: "unauthorized"}}

  def handle_in("authenticate", %{"email" => email, "password" => password}, socket) do
    case Phos.Users.get_user_by_email_and_password(email, password) do
      %Phos.Users.User{} = user ->
        Phos.Repo.preload(user, [:private_profile])
        |> load_geolocation(socket)
      _ -> {:reply, {:error, "Email and password combination not match"}, socket}
    end
  end

  def handle_info(:renew_token, %{assigns: %{user_id: id}} = socket) do
    Phos.Users.get_user!(id)
    |> Phos.Repo.preload([:private_profile])
    |> load_geolocation(socket)
    |> case do
      {_, {:ok, token}, socket} ->
        Process.send_after(self(), :renew_token, 60 * 1000 * 10)
        {:noreply, assign(socket, :session_token, token)}
      {_, {:error, _}, socket} -> {:noreply, socket}
    end
  end

  defp authorized?(%{assigns: %{session_token: token}} = _socket, id) when token != "" do
    case Phos.Guardian.decode_and_verify(token) do
      {:ok, %{"user_id" => user_id}} -> user_id == id
      _ -> false
    end
  end
  defp authorized?(_, _), do: false

  defp load_geolocation(%Phos.Users.User{id: id, username: username, private_profile: %Phos.Users.Private_Profile{geolocation: geolocations}} = user, socket) do
    teritories = Enum.reduce(geolocations, %{}, fn %{chronolock: chronolock, geohash: hash, location_description: desc}, acc ->
      Map.put(acc, String.downcase(desc), %{radius: chronolock, hash: :h3.to_string(hash)})
    end)
    opts = %{user_id: id, role: "pleb", username: username, teritory: teritories}
    create_user_token(user, opts, socket)
  end

  defp load_geolocation(%Phos.Users.User{id: id, username: username} = user, socket) do
    opts = %{user_id: id, role: "pleb", username: username}
    create_user_token(user, opts, socket)
  end

  defp create_user_token(user, opts, socket) do
    case Phos.Guardian.encode_and_sign(user, opts) do
      {:ok, token} -> {:reply, {:ok, token}, assign(socket, :session_token, token)}
      _ -> {:reply, {:error, "Cannot create token"}, socket}
    end
  end
end
