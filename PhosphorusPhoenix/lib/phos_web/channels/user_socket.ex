defmodule PhosWeb.UserSocket do
  use Phoenix.Socket
  alias PhosWeb.Menshen.Auth

  # A Socket handler
  #
  # It's possible to control the websocket connection and
  # assign values that can be accessed by your channel topics.

  ## Channels

  channel "archetype:usr:*", PhosWeb.UserChannel
  # channel "archetype:loc:*", PhosWeb.UserLocationChannel
  # channel "userfeed:*", PhosWeb.UserFeedChannel
  # channel "discovery:usr:*", PhosWeb.DiscoveryChannel
  channel "memory:user:*", PhosWeb.UserMemoryChannel
  channel "memory:location:*", PhosWeb.LocationMemoryChannel
  ## Transports
  #transport :websocket, Phoenix.Transports.WebSocket, check_origin: ["//localhost",  "//echo.scrb.ac"]

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.

  @impl true
  def connect(%{"token" => token}, _socket, _connect_info) when is_nil(token) or token == "", do: :error
  def connect(%{"token" => token} = _params, socket, _connect_info) when is_binary(token) do
    # Parsing of Authorising JWT vector and assigning to session
    case Auth.validate_user(token) do
      {:ok, %{"user_id" => user} = claims} ->
        from = self()
        spawn(fn -> track_user_location(from, claims) end)
        {:ok,
          socket
          |> assign(user_agent: claims, session_token: token, current_user: Phos.Users.get_user!(user))
        }
      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def connect(_params, _socket, _connect_info), do: :error

  defp track_user_location(pid, %{"territory" => territory, "user_id" => user_id} = claims) do
    Enum.map(territory, fn {key, val} ->
      case Map.get(val, "hash") do
        nil -> :ok
        hash -> do_track_user_location(pid, key, Phos.Mainland.World.locate(hash), user_id)
      end
    end)

    :ok
  end

  defp do_track_user_location(pid, key, location, user_id) when is_bitstring(location) do
    loc = location |> String.downcase() |> String.replace(" ", "_")
    PhosWeb.Presence.track(pid, "online_#{key}_location", loc, %{user_id: user_id})
  end
  defp do_track_user_location(_pid, _key, _loc, _user_id), do: :ok

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Elixir.PhosWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(_socket), do: nil
end
