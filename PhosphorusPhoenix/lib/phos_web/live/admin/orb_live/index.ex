defmodule PhosWeb.Admin.OrbLive.Index do
  use PhosWeb, :admin_view

  alias Phos.Action

  def mount(params, _session, socket) do
    %{data: orbs, meta: meta} = Action.filter_orbs_by_traits([], limit: 20, page: 1)
    {:ok, assign(socket, orbs: orbs, pagination: meta.pagination, traits: [], limit: 20)}
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

  def table_values(assigns) do
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

  def paginate(assigns) do
    ~H"""
      <nav class="isolate border border-gray-300 inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
        <%= if (@first), do: first_page(assigns) %>
        <%= prev_page(assigns) %>
        <%= paginate_value(assigns) %>
        <%= next_page(assigns) %>
        <%= if (@last), do: last_page(assigns) %>
      </nav>
    """
  end

  defp first_page(assigns) do
    %{meta: %{start: page, current: current}} = assigns
    base_class = "relative inline-flex items-center px-2 py-2 text-sm font-medium text-gray-500  border-r border-gray-300"

    current_class = case page == current do
      true -> base_class <> " bg-gray-50 cursor-not-allowed"
      _ -> base_class <> " hover:bg-gray-50"
    end

    ~H"""
      <%= live_patch to: Routes.admin_orb_index_path(PhosWeb.Endpoint, :index, page: page), class: current_class do %>
        <span class="sr-only">First</span>
        <div class="h-5 w-5 flex items-center justify-center">
          <%= for n <- [1, 2] do %>
            <svg class="h-5 w-5 -m-2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M12.79 5.23a.75.75 0 01-.02 1.06L8.832 10l3.938 3.71a.75.75 0 11-1.04 1.08l-4.5-4.25a.75.75 0 010-1.08l4.5-4.25a.75.75 0 011.06.02z" clip-rule="evenodd" />
            </svg>
          <% end %>
        </div>
      <% end %>
    """
  end

  defp prev_page(assigns) do
    %{meta: %{downstream: downstream, current: current}} = assigns
    base_class = "relative inline-flex items-center px-2 py-2 text-sm font-medium text-gray-500 border-l border-gray-300"

    current_class = case downstream do
      false -> base_class <> " bg-gray-50 cursor-not-allowed"
      _ -> base_class <> " hover:bg-gray-50"
    end

    expected_page = case downstream do
      false -> current
      _ -> current - 1
    end

    ~H"""
      <%= live_patch to: Routes.admin_orb_index_path(PhosWeb.Endpoint, :index, page: expected_page), class: current_class do %>
        <span class="sr-only">Previous</span>
        <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
          <path fill-rule="evenodd" d="M12.79 5.23a.75.75 0 01-.02 1.06L8.832 10l3.938 3.71a.75.75 0 11-1.04 1.08l-4.5-4.25a.75.75 0 010-1.08l4.5-4.25a.75.75 0 011.06.02z" clip-rule="evenodd" />
        </svg>
      <% end %>
    """
  end

  defp next_page(assigns) do
    %{meta: %{upstream: upstream, current: current}} = assigns
    base_class = "relative inline-flex items-center px-2 py-2 text-sm font-medium text-gray-500 border-l border-gray-300"

    current_class = case upstream do
      false -> base_class <> " bg-gray-50 cursor-not-allowed"
      _ -> base_class <> " hover:bg-gray-50"
    end

    expected_page = case upstream do
      false -> current
      _ -> current + 1
    end

    ~H"""
      <%= live_patch to: Routes.admin_orb_index_path(PhosWeb.Endpoint, :index, page: expected_page), class: current_class do %>
        <span class="sr-only">Next</span>
        <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
          <path fill-rule="evenodd" d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z" clip-rule="evenodd" />
        </svg>
      <% end %>
    """
  end

  defp last_page(assigns) do
    %{meta: %{end: page, current: current}} = assigns
    base_class = "relative inline-flex items-center px-2 py-2 text-sm font-medium text-gray-500 border-l border-gray-300"

    current_class = case page == current do
      true -> base_class <> " bg-gray-50 cursor-not-allowed"
      _ -> base_class <> " hover:bg-gray-50"
    end

    ~H"""
      <%= live_patch to: Routes.admin_orb_index_path(PhosWeb.Endpoint, :index, page: page), class: current_class do %>
        <span class="sr-only">Last</span>
        <div class="h-5 w-5 flex items-center justify-center">
          <%= for n <- [1, 2] do %>
            <svg class="h-5 w-5 -m-2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z" clip-rule="evenodd" />
            </svg>
          <% end %>
        </div>
      <% end %>
    """
  end

  def paginate_value(%{meta: %{end: page, current: current}, limit: limit} = assigns) when page > limit do
    num = Kernel.div(page, limit)
    ~H"""
      <%= for i <- 1..num do %>
        <.paginate_child number={i}, active={current == i} />
      <% end %>
    """
  end
  def paginate_value(_assigns), do: paginate_child(%{number: 1, active: true})

  def paginate_child(%{number: number, active: active} = assigns) when number != 0 do
    current_class = case active do
      true -> "relative z-10 inline-flex items-center border border-indigo-500 bg-indigo-50 px-4 py-2 text-sm font-medium text-indigo-600 focus:z-20"
      _ -> "relative inline-flex items-center border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-500 hover:bg-gray-50 focus:z-20"
    end

    ~H"""
      <%= live_patch number, to: Routes.admin_orb_index_path(PhosWeb.Endpoint, :index, page: number), class: current_class %>
    """
  end
  def paginate_child(assigns) do
    ~H"""
      <%= live_patch "...", to: "#", class: "relative inline-flex items-center border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-500 hover:bg-gray-50 focus:z-20" %>
    """
  end
end
