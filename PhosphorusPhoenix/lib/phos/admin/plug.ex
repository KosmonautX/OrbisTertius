defmodule Phos.Admin.Plug do
  use PhosWeb, :verified_routes
  import Plug.Conn, only: [get_session: 2, assign: 3, halt: 1]
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  def init(opts), do: opts
  def call(conn, _opts) do
    with token <- get_session(conn, :admin_token),
         {:ok, %Phos.Admin{} = admin} <- Phos.Admin.verify_token(token) do
      assign(conn, :current_admin, admin)
    else
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Restricted area")
        |> redirect(to: ~p"/admin/sessions/new")
        |> halt()
    end
  end
end
