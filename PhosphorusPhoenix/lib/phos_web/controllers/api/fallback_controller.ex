defmodule PhosWeb.API.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use PhosWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(PhosWeb.API.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, :unprocessable_entity}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(PhosWeb.ErrorJSON)
    |> render(:"422")
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(PhosWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(PhosWeb.ErrorJSON)
    |> render(:"403")
  end

  def call(conn, {:error, message}) when is_binary(message) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(PhosWeb.API.ChangesetView)
    |> render("error.json", reason: message)
  end

  def call(conn, _opts) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(PhosWeb.API.ChangesetView)
    |> render("error.json", reason: "")
  end
end