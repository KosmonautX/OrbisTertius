defmodule PhosWeb.Admin.OrbLive.Import do
  use PhosWeb, :admin_view

  @impl true
  def mount(_params, _session, socket) do
    Process.send_after(self(),  :live_orbs, 1000)
    {:ok, assign(socket, [loading: true, orbs: [], message: "", selected_orbs: [], show_detail_id: nil, show_modal: false])}
  end

  @impl true
  def handle_info(:live_orbs, socket) do
    case Phos.Action.import_today_orb_from_notion() do
      data when data == [] ->
        {:noreply, assign(socket, [message: "No Orbs scheduled for Today 🔮", loading: false])}
      data when is_list(data) ->
        {:noreply, assign(socket, [loading: false, orbs: Enum.reject(data,&(&1.done))])}
      _ -> {:noreply, assign(socket, [message: "Error fetching orbs", loading: false])}
    end
  end

  @impl true
  def handle_event("set-selected-orb", %{"selected" => selected}, %{assigns: %{selected_orbs: selected_orbs}} = socket) do
    case Enum.member?(selected_orbs, selected) do
      true -> {:noreply, assign(socket, :selected_orbs, selected_orbs -- [selected])}
      _ -> {:noreply, assign(socket, :selected_orbs, [selected | selected_orbs])}
    end
  end

  @impl true
  def handle_event("import-selected-orbs", _, %{assigns: %{selected_orbs: selected_orbs, orbs: orbs}} = socket) do
    # allow users to super user the user they login with instead or post on behalf of other users (notion)
    initiator = Phos.Users.get_admin()
    selected_orbs
    |> Enum.map(&String.to_integer/1)
    |> Enum.map(&Enum.at(orbs, &1))
    |> Enum.map(&PhosWeb.Util.ImageHandler.store_ext_links(&1, "ORB"))
    |> Enum.map(&map_to_orb_struct(&1, initiator))
    |> Phos.Action.create_orb_and_publish()
    |> case do
      [] -> {:noreply, socket
        |> put_flash(:error, "Orb(s) failed to import.")
        |> push_redirect(to: ~p"/admin/orbs")}
      data ->
        case contains_error?(data) do
          true ->
            {:noreply, socket
            |> put_flash(:error, "Orb(s) contains error. 💥")
            |> push_redirect(to: ~p"/admin/orbs")}
          _ ->
            {:noreply, socket
                |> put_flash(:info, "Orbs have been born 🥳 @" <> (DateTime.now!("Asia/Singapore") |> Calendar.strftime("%y-%m-%d %I:%M:%S %p")))
                |> push_redirect(to: ~p"/admin/orbs")}
            # legacy apis deprecated
            # case Phos.External.HeimdallrClient.post_orb(data) do
            #   {:ok, _response} ->
            #     {:noreply, socket
            #     |> put_flash(:info, "Orbs have been born 🥳 @" <> (DateTime.now!("Asia/Singapore") |> Calendar.strftime("%y-%m-%d %I:%M:%S %p")))
            #     |> push_redirect(to: ~p"/admin/orbs", replace: true)}
            #   {:error, message} ->
            #     {:noreply, socket
            #     |> put_flash(:error, "Take down Orbs 💥, failed to propogate to legacy api service
            #     #{inspect(message)}")
            #     |> push_redirect(to: ~p"/admin/orbs", replace: true)}
            # end

        end
    end
  end

  @impl true
  def handle_event("detail-orb", %{"index" => index}, %{assigns: %{orbs: _orbs}} = socket) do
    Process.send_after(self(), :marker_update, 500)
    Process.send_after(self(), :boundaries_update, 700)
    {:noreply, assign(socket, show_detail_id: String.to_integer(index), show_modal: true)}
  end

  @impl true
  def handle_event("close-and-select", _, %{assigns: %{show_detail_id: id, selected_orbs: selected_orbs}} = socket) do
    {:noreply, assign(socket, [show_detail_id: nil, selected_orbs: [to_string(id) | selected_orbs]])}
  end

  @impl true
  def handle_event("close-modal", _, socket), do: {:noreply, assign(socket, show_detail_id: nil, show_modal: false)}


  @impl true
  def handle_info(:boundaries_update, %{assigns: %{orbs: orbs, show_detail_id: id}} = socket) do
    geo_boundaries = case orb = show_detail_orb(id, orbs) do
                       %{geolocation: %{live: %{geohashes: hashes}}} ->
                         hashes
                       %{geolocation: %{live: %{latlon: latlon}}} ->
                         :h3.from_geo({latlon.lat, latlon.lon}, orb.geolocation.live.target)
                         |> :h3.k_ring(1)
                     end
                     |> Enum.map(&:h3.to_geo_boundary/1)
                     |> Enum.map(fn d -> Enum.map(d, &Tuple.to_list/1) end)

    {:noreply, push_event(socket, "add_polygon", %{geo_boundaries: geo_boundaries})}
  end

  @impl true
  def handle_info(:marker_update, %{assigns: %{orbs: orbs, show_detail_id: id}} = socket) do
    [lat, lon] = case show_detail_orb(id, orbs) do
                   %{geolocation: %{live: %{geohashes: hashes}}} ->
                     hashes|> List.first()
                     |> :h3.to_geo()
                     |> Tuple.to_list()

                  %{geolocation: %{live: %{latlon: coords}}} -> [coords.lat, coords.lon]
                  end
    {:noreply, push_event(socket, "centre_marker", %{latitude: lat, longitude: lon, geolock: 13})}
    end

  #slots
  def list_orbs_detail(assigns) do
    ~H"""
    <div class="pb-2 px-2">
      <div class="w-full px-4 grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4">
        <%= for {entry, index} <- Enum.with_index(@entries) do %>
          <.orb_card id={"orb_#{index}"} data={entry} selected_orbs={@selected_orbs} index={index} />
        <% end %>
      </div>
      <div id="confirmation" class="w-full flex flex-row-reverse">
        <%= if length(@selected_orbs) == 0 and length(@entries) > 0 do %>
          <button disabled={true} class="button button-sm">
            Choose your Orbs 😴
          </button>
        <% end %>
        <%= if length(@selected_orbs) > 0 and length(@entries) > 0 do %>
          <button class="button button-sm" type="button" phx-click="import-selected-orbs">
            Activate Orb ⚡
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  def orb_card(assigns) do
    ~H"""
    <div id={"orb_detail_#{@id}"} class="w-full hover:cursor-pointer" phx-click="set-selected-orb" phx-value-selected={@index}>
      <.card title={@data.title} id={@id} name="orb_modal" class={define_class(@index, @selected_orbs)}>
        <div class="px-2 pb-3">
          <%= if Map.get(@data, :lossy) do %>
            <img src={Map.get(@data, :lossy)} class="max-w-full h-auto mx-auto" alt="image here" />
          <% end %>
          <h3 class="text-sm mt-2 font-light">
            <i class="fa-solid fa-user mr-2"></i>
            <%= @data.username %>
          </h3>
          <h4 class="text-sm mt-2 font-light">
            <i class="fa-solid fa-location-dot mr-2"></i>
            <%= Map.get(@data, :where, "-") %>
          </h4>
        </div>
        <div class="px-2 pb-3">
          <button class="button button-xs button-primary" phx-click="detail-orb" phx-value-index={@index}>
            Detail
          </button>
          <button class="button button-xs" phx-click="set-selected-orb" phx-value-selected={@index}>
            <%= if selected_orbs?(@index, @selected_orbs), do: "Unselect", else: "select" %>
          </button>
        </div>
      </.card>
    </div>
    """
  end

  defp define_class(_, []), do: "bg-white"
  defp define_class(index, selected_orbs) do
    case Enum.member?(selected_orbs, "#{index}") do
      true -> "bg-blue-300"
      _ -> "bg-white"
    end
  end

  defp selected_orbs?(index, selected_orbs), do: Enum.member?(selected_orbs, "#{index}")

  defp map_to_orb_struct(orb, %{id: id}), do: map_to_orb_struct(orb, id)
  defp map_to_orb_struct(%{geolocation: %{live: %{geohashes: hashes}}} = orb, initiator_id) when is_binary(initiator_id) do
    title = Map.get(orb, :title, "")

    %{
      "id" => Map.get(orb, :id, nil) || Ecto.UUID.generate(),
      "active" => true,
      "locations" => Enum.map(hashes, &Map.new([{"id", &1}])),
      "title" => Map.get(orb, :outer_title, title),
      "initiator_id" => initiator_id,
      "payload" => %{"info" => orb.info, "inner_title" => title},
      "media" => orb.media,
      "source" => :web,
      "extinguish" => create_extinguish(orb.expires_in),
      "central_geohash" => List.first(hashes),
      "traits" => Map.get(orb, :traits, [])
    }
  end
  defp map_to_orb_struct(%{geolocation: %{live: live}} = orb, initiator_id) when is_binary(initiator_id) do
    %{
      "id" => Map.get(orb, :id, nil) || Ecto.UUID.generate(),
      "active" => true,
      "locations" => get_geolock_target(live) |> Enum.map(&Map.new([{"id", &1}])),
      "title" => orb.title,
      "initiator_id" => initiator_id,
      "payload" => %{"info" => orb.info},
      "media" => orb.media,
      "source" => :web,
      "extinguish" => create_extinguish(orb.expires_in),
      "central_geohash" => get_geohash(live),
      "traits" => Map.get(orb, :traits, [])
     }
  end

  defp get_geolock_target(%{target: 8} = geolock), do: [get_geohash(geolock)]
  defp get_geolock_target(geolock), do: get_geohash(geolock) |> :h3.k_ring(1)

  defp get_geohash(%{latlon: latlon, target: target}), do: :h3.from_geo({latlon.lat, latlon.lon}, target)

  def show_detail_orb(index, orbs) when is_integer(index), do: Enum.at(orbs, index)
  def show_detail_orb(_, _), do: %{}

  defp parse_as_html(data) do
    case Earmark.as_html(data) do
      {:ok, result, _} -> HtmlSanitizeEx.html5(result)
      _ -> "-"
    end
  end

  defp create_extinguish(expires_in, formatted \\ false) do
    time = NaiveDateTime.utc_now() |> NaiveDateTime.add(expires_in)

    case formatted do
      true -> Timex.format!(time, "{D} {Mshort} {YYYY} {h24}:{m}")
      _ -> time
    end
  end

  defp contains_error?(data) when  is_list(data) do
    Enum.filter(data, &filter_error/1)
    |> Enum.any?
  end
  defp contains_error?(_), do: true

  defp filter_error(%Phos.Action.Orb{}), do: false
  defp filter_error(_), do: true
end
