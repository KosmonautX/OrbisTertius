defmodule PhosWeb.OrbLive.Index do
  use PhosWeb, :live_view

  alias Phos.Action
  alias Phos.Action.Orb

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
    |> assign(:orbs, list_orbs())
    |> assign(:geolocation, %{live: %{}, work: %{}})
  }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Orb")
    |> assign(:orb, Action.get_orb!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Orb")
    |> assign(:orb, %Orb{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Orbs")
    |> assign(:orb, nil)
  end

  @impl true
  def handle_event("live_location_update", %{"longitude" => longitude, "latitude" => latitude}, socket) do
    updated_geolocation = get_and_update_in(socket.assigns.geolocation, Enum.map([:live, :geohash], &Access.key(&1, %{})), &{&1, %{hash: :h3.from_geo({latitude, longitude}, 10), radius: 10}})
    |> case do
         {past, present} -> unless past == present[:live][:geohash] do
             put_in(present, [:live, :geosub],
               Enum.map([8,9,10], fn res -> :h3.parent(present[:live][:geohash].hash,res) end)
               |> subscriber(present[:live][:geosub])
               )
             else
               present
             end
           end

    {:noreply, assign(socket, :geolocation, updated_geolocation)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    orb = Action.get_orb!(id)
    {:ok, _} = Action.delete_orb(orb)

    {:noreply, assign(socket, :orbs, list_orbs())}
  end

  defp list_orbs do
    Action.list_orbs()
  end

  defp subscriber(present, nil) do
    IO.puts("subscribe #{inspect(present)}")
    present |>Enum.map(fn new-> Phos.Pubsub.subscribe(loc_topic(new)) end)
    present
  end

  defp subscriber(present, past) do
    IO.puts("subscribe with past#{inspect(present)}")
    present -- past |> Enum.map(fn old -> old |> loc_topic() |> Phos.Pubsub.unsubscribe() end)
    past -- present |>Enum.map(fn new-> new |> loc_topic() |> Phos.Pubsub.subscribe() end)
    present
  end

  defp loc_topic(hash) when is_integer(hash), do: "LOC.#{hash}"
 end
