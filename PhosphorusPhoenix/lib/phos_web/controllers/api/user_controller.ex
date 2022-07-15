defmodule PhosWeb.API.UserController do
  use PhosWeb, :controller

  action_fallback PhosWeb.API.FallbackController

  def show_user_media(conn, %{"id" => id}) do
    json(conn, %{payload: Phos.Orbject.S3.get!("USR", id, "150x150") })
  end
end
