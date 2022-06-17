defmodule PhosWeb.SignUpLive.Index do
  use PhosWeb, :live_view

  @impl true
  def mount(_params, %{"current_user" => %Phos.Users.User{} = _user}, socket) do
    {:ok, socket
    |> put_flash(:info, "You've already signed up")
    |> push_redirect(to: "/orb", replace: true)}
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
    |> assign(changeset: Ecto.Changeset.change(%Phos.Users.User{}))}
  end

  @impl true
  def handle_event("sign_up", %{"user" => user_params},socket) do
    Phos.Users.create_user(user_params)
    |> case do
      {:ok, user} ->
           #Plug.Conn.put_session(socket, :current_user, user)
           create_token(user, socket)
      _ -> {:noreply, socket
      |> put_flash(:error, "Error while create a user")}
    end
  end

  @impl true
  def handle_info(:token, %{assigns: %{token: token}} = socket) do
    Process.send_after(self(), :token, 20 * 60 * 1000)
    case Phos.Guardian.refresh(token) do
      {:ok, _old, {new_token, _claims}} -> {:noreply, assign(socket, :token, new_token)}
      _ -> {:noreply, socket}
    end
  end

  defp create_token(user, socket) do
    case Phos.Guardian.encode_and_sign(user) do
      {:ok, token, _claims} ->
        Process.send_after(self(), :token, 20 * 60 * 1000)
        {:noreply, socket
      |> put_flash(:info, "Successfully create a user")
      |> assign(:token, token)}
      _ ->
        {:noreply, socket
      |> put_flash(:error, "Something went wrong while create token")}
    end
  end
end
