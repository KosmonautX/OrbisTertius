defmodule Phos.Admin.Mounter do
  import Phoenix.LiveView
  import Phoenix.Component
  import Phoenix.VerifiedRoutes, only: [path: 2]

  @router PhosWeb.Router

  def on_mount(_, _params, %{"admin_token" => token} = _session, socket) do
    case Phos.Admin.verify_token(token) do
      {:ok, admin} -> {:cont, assign(socket, :current_admin, admin)}
      _ -> on_mount(nil, nil, nil, socket)
    end
  end

  def on_mount(_, _, _, socket), do: 
    {:halt, redirect(socket, to: path(socket, ~p"/admin/sessions/new"))}
end
