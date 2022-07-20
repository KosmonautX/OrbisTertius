defmodule PhosWeb.Admin.OrbLive.Show do
  use PhosWeb, :admin_view

  alias Phos.Action

  def mount(%{"id" => id} = _params, _session, socket) do
    case Action.get_orb(id) do
      {:ok, orb} -> {:ok, assign(socket, :orb, orb)}
      _ -> {:ok, assign(socket, :orb, nil)}
    end
  end
end
