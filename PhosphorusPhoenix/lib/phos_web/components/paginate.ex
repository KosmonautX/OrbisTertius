defmodule PhosWeb.Components.Pagination do
  use PhosWeb, :live_component

  @impl true
  def mount(socket), do: {:ok, socket}

  @impl true
  def update(assigns, socket) do
    {:ok, 
      assign(socket, assigns)
      |> assign_new(:first, fn -> true end)
      |> assign_new(:last, fn -> true end)
      |> assign_new(:route_path, fn -> :root_path end)
      |> assign_new(:route_method, fn -> :index end)
      |> assign_new(:limit, fn -> 10 end)}
  end

  @impl true
  def render(assigns) do
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

  defp first_page(%{route_path: route, route_method: method} = assigns) do
    %{meta: %{start: page, end: final, current: current}} = assigns
    base_class = "relative inline-flex items-center px-2 py-2 text-sm font-medium text-gray-500  border-r border-gray-300"

    current = case final == 0 and page == 0 do
      true -> page
      _ -> current
    end

    current_class = case page == current do
      true -> base_class <> " bg-gray-50 cursor-not-allowed"
      _ -> base_class <> " hover:bg-gray-50"
    end

    ~H"""
      <%= live_patch to: apply(Routes, route, [PhosWeb.Endpoint, method, [page: page]]), class: current_class do %>
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

  defp last_page(%{route_path: route, route_method: method} = assigns) do
    %{meta: %{end: page, start: start, current: current}} = assigns
    base_class = "relative inline-flex items-center px-2 py-2 text-sm font-medium text-gray-500 border-l border-gray-300"

    current = case start == 0 and page == 0 do
      true -> page
      _ -> current
    end

    current_class = case page == current do
      true -> base_class <> " bg-gray-50 cursor-not-allowed"
      _ -> base_class <> " hover:bg-gray-50"
    end

    ~H"""
      <%= live_patch to: apply(Routes, route, [PhosWeb.Endpoint, method, [page: page]]), class: current_class do %>
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

  defp prev_page(%{route_path: route, route_method: method} = assigns) do
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
      <%= live_patch to: apply(Routes, route, [PhosWeb.Endpoint, method, [page: expected_page]]), class: current_class do %>
        <span class="sr-only">Previous</span>
        <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
          <path fill-rule="evenodd" d="M12.79 5.23a.75.75 0 01-.02 1.06L8.832 10l3.938 3.71a.75.75 0 11-1.04 1.08l-4.5-4.25a.75.75 0 010-1.08l4.5-4.25a.75.75 0 011.06.02z" clip-rule="evenodd" />
        </svg>
      <% end %>
    """
  end

  defp next_page(%{route_path: route, route_method: method} = assigns) do
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
      <%= live_patch to: apply(Routes, route, [PhosWeb.Endpoint, method, [page: expected_page]]), class: current_class do %>
        <span class="sr-only">Next</span>
        <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
          <path fill-rule="evenodd" d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z" clip-rule="evenodd" />
        </svg>
      <% end %>
    """
  end

  def paginate_value(%{meta: %{end: page, current: current}, limit: limit} = assigns) when page > limit do
    num = Kernel.div(page, limit)
    ~H"""
      <%= for i <- 1..num do %>
        <.paginate_child number={i}, active={current == i}  route_path={@route_path} route_method={@route_method} />
      <% end %>
    """
  end
  def paginate_value(%{meta: %{start: start}}) when start == 0, do: paginate_child(%{number: 1, active: false})
  def paginate_value(_assigns), do: paginate_child(%{number: 1, active: true})

  def paginate_child(%{number: number, active: active, route_path: route, route_method: method} = assigns) when number != 0 do
    current_class = decide_active_class(active)

    ~H"""
      <%= live_patch number, to: apply(Routes, route, [PhosWeb.Endpoint, method, [page: number]]), class: current_class %>
    """
  end
  def paginate_child(%{active: active} = assigns) do
    IO.inspect(active)
    current_class = decide_active_class(active)

    ~H"""
      <%= live_patch "...", to: "#", class: current_class %>
    """
  end

  defp decide_active_class(true), do: "relative z-10 inline-flex items-center border border-indigo-500 bg-indigo-50 px-4 py-2 text-sm font-medium text-indigo-600 focus:z-20"
  defp decide_active_class(_), do: "relative inline-flex items-center border border-gray-300 bg-gray-50 px-4 py-2 text-sm font-medium text-gray-500 hover:bg-gray-50 focus:z-20"
end
