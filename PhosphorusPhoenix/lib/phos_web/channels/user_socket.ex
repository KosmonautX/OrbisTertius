defmodule PhosWeb.UserSocket do
  use Phoenix.Socket
  alias PhosWeb.Menshen.Auth

  # A Socket handler
  #
  # It's possible to control the websocket connection and
  # assign values that can be accessed by your channel topics.

  ## Channels

  channel "archetype:usr:*", PhosWeb.UserChannel
  channel "archetype:loc:*", PhosWeb.LocationChannel

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
  def connect(%{"token" => token} = _params, socket, _connect_info) do
    # Parsing of Authorising JWT vector and assigning to session
    case Auth.validate(token) do
      {:ok, claims} ->
        {:ok, socket |> assign(:user_agent, claims) |> assign(:session_token, token)

        }
      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def connect(_params, _socket, _connect_info) do
    # {:ok, socket}
    :error
  end

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
