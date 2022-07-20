defmodule Phos.Admin.Mounter do
  import Phoenix.LiveView

  def on_mount(_, _params, %{"admin_token" => token} = _session, socket) do
    case Phos.Admin.verify_token(token) do
      {:ok, admin} -> {:cont, assign(socket, :current_admin, admin)}
      _ -> on_mount(nil, nil, nil, socket)
    end
  end

  def on_mount(_, _, _, socket), do: {:halt, redirect(socket, to: PhosWeb.Router.Helpers.admin_session_path(socket, :new))}
end
