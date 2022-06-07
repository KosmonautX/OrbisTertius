defmodule PhosWeb.OrbLive.Index do
  use PhosWeb, :live_view

  alias Phos.Action
  alias Phos.Action.Orb
  alias Phos.PubSub

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
    |> assign(:orbs, [])
    |> assign(:geolocation, %{live: %{},
        home: %{
          geohash: %{hash: 623276184907907071, radius: 10},
          geosub: []
        },
        work: %{
          geohash: %{hash: 623276216933351423, radius: 10},
          geosub: []
        }
     })
    |> assign(:home_orbs, [])
    |> assign(:work_orbs, [])
    # |> assign(:orbs_home,
    #   Enum.map([8,9,10], fn res -> :h3.parent(socket.assigns.geolocation[:home][:geohash].hash,res) end)
    #     |> Phos.Action.get_orbs_by_geohashes()
    #     |> Enum.sort_by(&Map.fetch(&1, :inserted_at), :desc))
    #|> assign(:geolocation, User.get_location_pref())
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
    IO.inspect(socket.assigns.geolocation)
    updated_geolocation = get_and_update_in(socket.assigns.geolocation, Enum.map([:live, :geohash], &Access.key(&1, %{})), &{&1, %{hash: :h3.from_geo({latitude, longitude}, 10), radius: 10}})
    |> case do
         {past, present} -> unless past == present[:live][:geohash] do
             put_in(present, [:live, :geosub],
               Enum.map([8,9,10], fn res -> :h3.parent(present[:live][:geohash].hash,res) end)
               |> loc_subscriber(present[:live][:geosub])
               )
             else
               present
             end
           end

    # Get orbs from geosub live
    live_orbs =
      Phos.Action.get_orbs_by_geohashes((Map.get(updated_geolocation, :live) |> Map.get(:geosub)))
      |> Enum.sort_by(&Map.fetch(&1, :inserted_at), :desc)

    home_orbs =
      Enum.map([8,9,10], fn res -> :h3.parent(socket.assigns.geolocation[:home][:geohash].hash,res) end)
        |> Phos.Action.get_orbs_by_geohashes()
        |> Enum.sort_by(&Map.fetch(&1, :inserted_at), :desc)

    work_orbs =
      Enum.map([8,9,10], fn res -> :h3.parent(socket.assigns.geolocation[:work][:geohash].hash,res) end)
      |> IO.inspect()
        |> Phos.Action.get_orbs_by_geohashes()
        |> Enum.sort_by(&Map.fetch(&1, :inserted_at), :desc)


    # IO.inspect(updated_geolocation)

    {:noreply, socket
      |> assign(:geolocation, updated_geolocation)
      |> assign(:orbs, live_orbs)
      |> assign(:home_orbs, home_orbs)
      |> assign(:work_orbs, work_orbs)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    orb = Action.get_orb!(id)
    {:ok, _} = Action.delete_orb(orb)

    {:noreply, assign(socket, :orbs, list_orbs())}
  end

  @impl true
  def handle_info({PubSub, {:orb, :genesis}, message}, socket) do
    IO.puts("genesis #{inspect(message)}")
    {:noreply, socket}
  end

  def handle_info({PubSub, {:orb, :mutation}, message}, socket) do
    IO.puts("mutate #{inspect(message)}")
    {:noreply, socket}
  end

  def handle_info({PubSub, {:orb, :deactivation}, message}, socket) do
    IO.puts("deactivate #{inspect(message)}")
    {:noreply, socket}
  end

  defp list_orbs do
    Action.list_orbs()
  end

  defp loc_subscriber(present, nil) do
    IO.puts("subscribe #{inspect(present)}")
    present |>Enum.map(fn new-> Phos.PubSub.subscribe(loc_topic(new)) end)
    present
  end

  defp loc_subscriber(present, past) do
    IO.puts("subscribe with past#{inspect(present)}")
    present -- past |> Enum.map(fn old -> old |> loc_topic() |> Phos.PubSub.unsubscribe() end)
    past -- present |>Enum.map(fn new-> new |> loc_topic() |> Phos.PubSub.subscribe() end)
    present
  end

  defp loc_topic(hash) when is_integer(hash), do: "LOC.#{hash}"

  defp orb_loc_publisher(orb, event, to_locations) do
    to_locations |> Enum.map(fn loc-> Phos.PubSub.publish(orb, {:orb, event}, loc_topic(loc)) end)
  end

  defp loc_topic(hash) when is_integer(hash), do: "LOC.#{hash}"
 end
