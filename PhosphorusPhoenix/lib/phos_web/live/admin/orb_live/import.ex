defmodule PhosWeb.Admin.OrbLive.Import do
  use PhosWeb, :admin_view

  alias PhosWeb.Components.{Card}

  @impl true
  def mount(_params, _session, socket) do
    Process.send_after(self(),  :live_orbs, 1000)
    {:ok, assign(socket, [loading: true, orbs: [], message: "", selected_orbs: [], show_detail_id: nil])}
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
    initiator_id = 1

    selected_orbs
    |> Enum.map(&String.to_integer/1)
    |> Enum.map(&Enum.at(orbs, &1))
    |> Enum.map(&map_to_orb_struct(&1, initiator_id))
    {:noreply, socket}
  end

  @impl true
  def handle_event("detail-orb", %{"index" => index}, %{assigns: %{orbs: _orbs}} = socket) do
    Process.send_after(self(), :marker_update, 500)
    Process.send_after(self(), :boundaries_update, 700)
    {:noreply, assign(socket, :show_detail_id, String.to_integer(index))}
  end

  @impl true
  def handle_event("close-modal", _, socket), do: {:noreply, assign(socket, :show_detail_id, nil)}

  @impl true
  def handle_info(:live_orbs, socket) do
    case Phos.Action.import_today_orb_from_notion() do
      data when data == [] -> {:noreply, assign(socket, [message: "Today orbs is empty", loading: false])}
      data when is_list(data) -> {:noreply, assign(socket, [loading: false, orbs: Enum.reject(data,&(&1.done))])}
      _ -> {:noreply, assign(socket, [message: "Error fetching orbs", loading: false])}
    end
  end

  @impl true
  def handle_info(:boundaries_update, %{assigns: %{orbs: orbs, show_detail_id: id}} = socket) do
    geo_boundaries =
      show_detail_orb(id, orbs)
      |> Kernel.get_in([:geolocation, :live, :geohashes])
      |> Enum.map(&:h3.to_geo_boundary/1)
      |> Enum.map(fn d -> Enum.map(d, &Tuple.to_list/1) end)
    {:noreply, push_event(socket, "add_polygon", %{geo_boundaries: geo_boundaries})}
  end

  @impl true
  def handle_info(:marker_update, %{assigns: %{orbs: orbs, show_detail_id: id}} = socket) do
    [lat, lon] =
      show_detail_orb(id, orbs)
      |> Kernel.get_in([:geolocation, :live, :geohashes])
      |> List.first()
      |> :h3.to_geo()
      |> Tuple.to_list()
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
          <button disabled={true} class="button-sm">
            Import selected orbs
          </button>
        <% end %>
        <%= if length(@selected_orbs) > 0 and length(@entries) > 0 do %>
          <button class="button-sm" type="button" phx-click="import-selected-orbs">
            Import selected orbs
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  def orb_card(assigns) do
    ~H"""
    <div id={"orb_detail_#{@id}"} class="w-full hover:cursor-pointer" phx-click="set-selected-orb" phx-value-selected={@index}>
      <.live_component module={PhosWeb.Components.Card} title={@data.title} id={@id} name="name" class={define_class(@index, @selected_orbs)}>
        <div class="px-2 pb-3">
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
          <button class="button-sm" phx-click="detail-orb" phx-value-index={@index}>
            Detail
          </button>
          <button class="button-sm" phx-click="set-selected-orb" phx-value-selected={@index}>
            <%= if selected_orbs?(@index, @selected_orbs), do: "Unselect", else: "select" %>
          </button>
        </div>
      </.live_component>
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

  defp map_to_orb_struct(%{geolocation: %{live: %{geohashes: hashes}}} = orb, initiator_id) do
    title = Map.get(orb, :title, "")

    %{
      "id" => Ecto.UUID.generate(),
      "geolocation" => hashes,
      "title" => Map.get(orb, :outer_title, title),
      "initiator_id" => initiator_id,
      "payload" => %{"info" => orb.info, "inner_title" => title},
      "media" => orb.media,
      "orb_source" => :web,
      "extinguish" => create_extinguish(orb.expires_in),
      "central_geohash" => List.first(hashes),
      "traits" => Map.get(orb, :traits, [])
    }
  end
  defp map_to_orb_struct(%{geolocation: %{live: live}} = orb, initiator_id) do
    %{
      "id" => Ecto.UUID.generate(),
      "geolocation" => get_geolock_target(live),
      "title" => orb.title,
      "initiator_id" => initiator_id,
      "payload" => %{"info" => orb.info},
      "media" => orb.media,
      "orb_source" => :web,
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
end
