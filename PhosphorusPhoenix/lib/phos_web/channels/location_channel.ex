defmodule PhosWeb.UserLocationChannel do
  use PhosWeb, :channel
  alias PhosWeb.Menshen.Auth
  alias Phos.Action
  alias Phos.Users
  alias Phos.PubSub
  alias Phos.Geographer


  @impl true

  def join("archetype:loc:" <> user_id , _payload, socket) do
    # if exists on the app
    # preload geolocation preferences of user_id
    if authorized?(socket, user_id) do
    {:ok, socket
    |> assign(:user_id, user_id)
    |>assign(:geolocation, %{})}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end


  @impl true

  def handle_in("location_update", %{"name"=> name,"geohash"=> hash}, socket) when name in ["home", "work", "live"] do
    # check name against jwt using authorized
    IO.puts " in paris #{inspect(socket.assigns.geolocation)}"
    updated_geolocation = get_and_update_in(socket.assigns.geolocation, Enum.map([name, :geohash], &Access.key(&1, %{})), &{&1, %{hash: :h3.parent(hash, 10), radius: 10}})
    |> case do
         {past, present} ->
           unless past == present[name][:geohash] do
             neosubs = Enum.map([8,9,10], fn res -> :h3.parent(present[name][:geohash].hash,res) end)
             |> loc_subscriber(present[name][:geosub])
             #IO.puts "nigmas in neochina #{inspect(neosubs)}"

             put_in(present, [name, :geosub], neosubs)
           else
             present
           end
       end
    {:noreply, assign(socket, :geolocation, updated_geolocation)}
  end

  def handle_in("location_update", _payload, socket) do
    IO.puts("invalid payload location update")
    {:noreply, socket}
  end


  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    IO.inspect(socket)
    {:reply, {:ok, payload}, socket}
  end

  # Add authorization logic here as required. Process send_after for auth channel
  defp authorized?(socket, id) do
    case Auth.validate(socket.assigns.session_token) do
      {:ok , claims} ->
        if claims["user_id"] == socket.assigns.user_agent["user_id"] and claims["user_id"] == id do
          true
        else
          false
        end
      { :error, _error } ->
        {:error,  :authentication_required}
    end
  end

  defp loc_subscriber(present, nil) do
    IO.puts("subscribe #{inspect(present)}")
    present |>Enum.map(fn new-> Phos.PubSub.subscribe(loc_topic(new)) end)
    present
  end

  defp loc_subscriber(present, past) do
    IO.puts("subscribe with past#{inspect(present)}")
    present -- past |> Enum.map(fn old -> old |> loc_topic() |> PubSub.unsubscribe() |> IO.inspect() end)
    past -- present |>Enum.map(fn new-> new |> loc_topic() |> PubSub.subscribe() |> IO.inspect() end)
    present
  end

  defp loc_reverie(present, nil, socket) do
    present |> Action.get_orbs_by_geohashes()
    present
  end

  defp loc_reverie(present, past, socket) do
    past -- present |>  Action.get_orbs_by_geohash()
    present
  end

  defp loc_topic(hash) when is_integer(hash), do: "LOC.#{hash}"

end
