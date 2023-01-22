defmodule PhosWeb.API.TribunalController do
  use PhosWeb, :controller

  action_fallback PhosWeb.API.FallbackController


  def report_user(%Plug.Conn{assigns: %{current_user: user}} = conn, %{"id" => id, "message" => message} = report) when is_list(message) do
    with {:ok, _id} <-  Ecto.UUID.cast(id) do
      Phos.External.TelegramClient.report(user, report |> Map.put("archetype", "USR"))
      json(conn, %{report: report})
    else
      nil -> {:error, :not_found}
    end
  end

  def report_orb(%Plug.Conn{assigns: %{current_user: user}} = conn, %{"id" => id, "message" => message} = report) when is_list(message) do
    with {:ok, _id} <-  Ecto.UUID.cast(id) do
      Phos.External.TelegramClient.report(user, report |> Map.put("archetype", "ORB"))
      json(conn, %{report: report})
    else
      nil -> {:error, :not_found}
    end
  end


end
