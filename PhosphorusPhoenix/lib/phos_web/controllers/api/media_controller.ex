defmodule PhosWeb.API.MediaController do
  use PhosWeb, :controller
  alias Phos.Orbject.Structure
  action_fallback PhosWeb.API.FallbackController


  def show(conn, params = %{"media" => [_|_]}) do
    with {:ok, media} <- Structure.apply_media_changeset(params) do
      conn
      |> put_status(200)
      |> json(%{media: Phos.Orbject.S3.get_all!(media)})
    end
  end
end
