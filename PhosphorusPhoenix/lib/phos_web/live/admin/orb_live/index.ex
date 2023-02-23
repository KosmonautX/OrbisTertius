defmodule PhosWeb.Admin.OrbLive.Index do
  use PhosWeb, :admin_view

  alias Phos.Action


  def mount(_params, _session, socket) do
    limit = 20
    page = 1
    %{data: orbs, meta: meta} = filter_by_traits("", limit: limit, page: page)
    {:ok, assign(socket, orbs: orbs, pagination: meta.pagination, traits: "", limit: limit, current: page)}
  end

  def handle_params(%{"page" => page} = _params, _url,%{assigns: %{traits: traits, pagination: pagination, limit: limit} = _assigns} = socket) do
    expected_page = parse_integer(page)

    case expected_page == pagination.current do
      true -> {:noreply, assign(socket, current: expected_page)}
      _ ->
        %{data: orbs, meta: meta} = filter_by_traits(traits, limit: limit, page: expected_page)
        {:noreply, assign(socket, orbs: orbs, pagination: meta.pagination, current: expected_page)}
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

  def handle_event("search", %{"search" => %{"traits" => keyword}}, socket) do
    case String.length(keyword) > 3 do
      true ->
        %{data: orbs, meta: meta} = filter_by_traits(keyword)
        {:noreply, assign(socket, orbs: orbs, traits: keyword, pagination: meta.pagination)}
      _ -> {:noreply, socket}
    end
  end

  defp filter_by_traits(keyword, options \\ [])
  defp filter_by_traits(keyword, options) when is_list(keyword), do: Action.filter_orbs_by_traits(keyword, options)
  defp filter_by_traits(keyword, options) do
    keyword
    |> String.trim()
    |> case do
      "" -> []
      key -> String.split(key, ",")
    end
    |> filter_by_traits(options)
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
  def table_values(assigns) do
    ~H"""
      <%= for {entry, index} <- Enum.with_index(@entries) do %>
        <tr>
          <th class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4 text-left"><%= index + 1 %></th>
          <.table_column value={live_redirect(entry.title, to: ~p"/admin/orbs/#{entry}")} />
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
