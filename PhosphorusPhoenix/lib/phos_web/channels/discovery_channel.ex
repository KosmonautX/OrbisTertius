defmodule PhosWeb.DiscoveryChannel do
  use PhosWeb, :channel

  @visibility [8]
  @location_type ["home", "work", "live"]

  def join("discovery:usr:" <> id, _payload, socket) do
    if authorized?(socket, id) do
      Process.send_after(self(), :geoinitiation, 500)
      {:ok, assign(socket, locations: %{})}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("discover", _payload, %{assigns: %{current_user: user}} = socket) do
    geohashes = Map.get(user, :private_profile, %{}) |> Map.get(:geolocation, []) |> Enum.map(&(&1.id))
    orbs = Phos.Action.users_by_geohashes({geohashes, user.id}, 1)
    {:noreply, assign(socket, :orbs, orbs.data)}
  end

  def handle_in("unsubscribe", %{"name" => name, "locations" => locs}, %{assigns: %{locations: locations}} = socket) do
    case Map.get(locations, name) do
      nil -> {:noreply, socket}
      locs ->
        location_unsubscribe(locs)
        {:noreply, assign(socket, :locations, Map.delete(locations, name))}
    end
  end

  def handle_in("location_update", %{"name" => name, "geohash" => hash}, %{assigns: %{locations: locations}} = socket) when name in @location_type do
    geos = Enum.map(@visibility, fn res -> :h3.parent(hash, res) end)
    case Map.get(locations, name) do
      nil -> {:noreply, assign(socket, :locations, Map.put(locations, name, geos))}
      locs ->
        location_unsubscribe(locs)
        location_subscribe(geos)
        {:noreply, assign(socket, :locations, %{locations | name => geos})}
    end
  end

  def handle_info(:geoinitiation, %{assigns: %{current_user: user, locations: locations}} = socket) do
    {discoveries, addresses} = geolocation_decider(user, locations)
    Enum.each(addresses, fn {_k, vals} -> location_subscribe(vals) end)
    {:noreply, assign(socket, orbs: discoveries, locations: addresses)}
  end


  defp geolocation_decider(%{private_profile: %Ecto.Association.NotLoaded{}} = user, locations) do
    send(self(), :private_profile_loader)
    Phos.Repo.preload(user, :private_profile)
    |> geolocation_decider(locations)
  end

  defp geolocation_decider(%{private_profile: %{geolocation: locations}}, existing_locations) when length(locations) > 0 do
    geos  = orb_location_by_geohash(locations, existing_locations)
    addrs = orb_addresses(locations)
    {geos, addrs}
  end

  defp geolocation_decider(_, geohashes), do: {geohashes, %{}}

  defp orb_location_by_geohash(locations, existing_geos) do
    Enum.map(locations, fn %{geohash: geohash} ->
      Enum.reduce(@visibility, existing_geos, fn curr, acc ->
        Map.put(acc, :h3.parent(geohash, curr), Phos.Action.get_orb_by_trait_geo([:h3.parent(geohash, curr)], ["personal"]))
      end)
    end)
    |> Enum.reduce(fn x, acc ->
      Map.merge(acc, x)
    end)
  end

  defp orb_addresses(locations) do
    for %{id: id, geohash: geohash} <- locations, into: %{} do
      {to_string(id), Enum.map(@visibility, fn res -> :h3.parent(geohash, res) end)}
    end
  end

  defp location_unsubscribe(location) when is_number(location), do: Phos.PubSub.unsubscribe(topic(location))
  defp location_unsubscribe(locations) when is_list(locations), do: Enum.each(locations, &location_unsubscribe/1)

  defp location_subscribe(location) when is_number(location), do: Phos.PubSub.subscribe(topic(location))
  defp location_subscribe(locations) when is_list(locations), do: Enum.each(locations, &location_subscribe/1)

  defp topic(hash), do: "LOC.#{hash}"
end
