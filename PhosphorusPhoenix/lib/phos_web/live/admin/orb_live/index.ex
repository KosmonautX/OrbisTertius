defmodule PhosWeb.Admin.OrbLive.Index do
  use PhosWeb, :admin_view

  alias Phos.Action

  def mount(params, _session, socket) do
    %{data: orbs, meta: meta} = Action.filter_orbs_by_traits([], limit: 10, page: 1)
    {:ok, assign(socket, orbs: orbs, pagination: meta.pagination, traits: [], limit: 10)}
  end

  def handle_params(%{"page" => page} = params, _url,%{assigns: %{traits: traits, pagination: pagination, limit: limit}} = socket) do
    expected_page = parse_integer(page)

    case expected_page == pagination.current do
      true -> {:noreply, socket}
      _ -> 
        %{data: orbs, meta: meta} = Action.filter_orbs_by_traits(traits, limit: limit, page: expected_page)
        {:noreply, assign(socket, orb: orbs, pagination: meta.pagination)}
    end
  end

  def handle_params(_params, _url, socket), do: {:noreply, socket}

  defp parse_integer(text) do
    try do
      String.to_integer(text)
    rescue
      ArgumentError -> 1
    end
  end

  defp get_all_active_orbs(params) do
    params
    |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
    |> Action.list_all_active_orbs()
  end

  def handle_event("search", %{"search" => %{"traits" => keyword}}, socket) do
    case String.length(keyword) > 3 do
      true ->
        orbs = filter_by_traits(keyword)
        {:noreply, assign(socket, :orbs, orbs)}
      _ -> {:noreply, socket}
    end
  end

  defp filter_by_traits(keyword) do
    String.split(keyword, ",")
    |> Enum.map(&String.trim(&1, " "))
    |> Action.get_orbs_by_trait()
  end

  # slots
  def header_item(assigns) do
    ~H"""
      <th class="px-6 align-middle border border-solid py-3 text-xs uppercase border-l-0 border-r-0 whitespace-nowrap font-semibold text-left bg-gray-50 text-gray-500 border-gray-100"><%= @title %></th>
    """
  end

  def table_values(%{entries: []} = assigns) do
    ~H"""
      <tr>
          <td colspan="6" class="border-t-0 px-6 align-middle text-center border-l-0 border-r-0 text-xs italic whitespace-nowrap p-4 text-left">No Orbs found</td>
      </tr>
    """
  end
  def table_values(%{entries: entries} = assigns) do
    ~H"""
      <%= for {entry, index} <- Enum.with_index(@entries) do %>
        <tr>
          <th class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4 text-left"><%= index + 1 %></th>
          <.table_column value={live_redirect(entry.title, to: Routes.admin_orb_show_path(@socket, :show, entry.id))} />
          <.table_column value={entry.initiator.username} />
          <.table_column value={entry.source} />
          <.table_column value={entry.traits} />
          <.table_column value={Timex.format!(entry.inserted_at, "{D} {Mshort} {YY} {h24}:{m}")} />
        </tr>
      <% end %>
    """
  end

  def table_column(assigns) do
    ~H"""
      <td class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4">
        <%= if is_list(@value), do: raw Enum.join(@value, "<br />") %>
        <%= unless is_list(@value), do: @value %>
      </td>
    """
  end
end
