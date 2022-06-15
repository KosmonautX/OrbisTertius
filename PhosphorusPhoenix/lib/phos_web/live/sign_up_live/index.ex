defmodule PhosWeb.SignUpLive.Index do
  use PhosWeb, :live_view

  @impl true
  def mount(_params, %{"current_user" => %Phos.Users.User{} = _user}, socket) do
    {:ok, socket
    |> put_flash(:info, "You've already signed up")
    |> push_redirect(to: "/", replace: true)}
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
    |> assign(changeset: Ecto.Changeset.change(%Phos.Users.User{}))
    |> assign(orbs: [], home_orbs: [], work_orbs: [],
      geolocation: %{
        live: %{},
        home: %{},
        work: %{}
    })}
  end

  @impl true
  def handle_event("sign_up", %{"user" => user_params}, %{assigns: %{geolocation: geolocation}} = socket) do
    geohash = %{
      type: "live",
      geohash: get_in(geolocation, [:live, :geohash, :hash]),
      radius: get_in(geolocation, [:live, :geohash, :radius])
    }
    user_params
    |> Map.put("geohash", [geohash])
    |> Phos.Users.create_user()
    |> case do
      {:ok, user} -> create_token(user, socket)
      _ -> {:noreply, socket
      |> put_flash(:error, "Error while create a user")}
    end
  end

  @impl true
  def handle_event("live_location_update", %{"longitude" => longitude, "latitude" => latitude}, socket) do
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

    {:noreply, socket
      |> assign(:geolocation, updated_geolocation)}
  end

  @imple true
  def handle_info(:token, %{assigns: %{token: token}} = socket) do
    Process.send_after(self(), :token, 20 * 60 * 1000)
    case Phos.Guardian.refresh(token) do
      {:ok, _old, {new_token, _claims}} -> {:noreply, assign(socket, :token, new_token)}
      _ -> {:noreply, socket}
    end
  end

  defp create_token(user, socket) do
    case Phos.Guardian.encode_and_sign(user) do
      {:ok, token, _claims} ->
        Process.send_after(self(), :token, 20 * 60 * 1000)
        {:noreply, socket
      |> put_flash(:info, "Successfully create a user")
      |> assign(:token, token)}
      _ ->
        {:noreply, socket
      |> put_flash(:error, "Something went wrong while create token")}
    end
  end

  defp loc_subscriber(present, nil) do
    present
    |> Enum.map(fn new-> Phos.PubSub.subscribe(loc_topic(new)) end)
  end

  defp loc_topic(hash) when is_integer(hash), do: "LOC.#{hash}"
  defp loc_topic(rest), do: "LOC.#{rest}"
end
