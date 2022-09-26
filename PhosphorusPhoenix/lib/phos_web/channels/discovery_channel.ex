defmodule PhosWeb.DiscoveryChannel do
  use PhosWeb, :channel

  def join("discovery:" <> id, _payload, socket) do
    if authorized?(socket, id) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("discover", _payload, %{assigns: %{current_user: user}} = socket) do
    current_user = Phos.Repo.preload(user, :private_profile)
    geohashes = Map.get(current_user, :private_profile, %{}) |> Map.get(:geolocation, []) |> Enum.map(&(&1.id))
    orbs = Phos.Action.get_orb_by_trait_geo(geohashes, ["personal"])
    {:noreply, assign(socket, :orbs, orbs)}
  end
end
