defmodule PhosWeb.Components.Pagination do
  use PhosWeb, :live_component

  @impl true
  def mount(socket), do: {:ok, socket}

  @impl true
  def update(assigns, socket) do
    # require IEx; IEx.pry()
    {:ok,
      socket
      |> assign(:current, assigns.current)
      |> assign(:meta, assigns.meta)
      |> assign(:route_path, assigns.route_path)
      |> assign_new(:active, fn -> false end)
      |> assign_new(:number, fn -> 1 end)
      |> assign_new(:first, fn -> true end)
      |> assign_new(:last, fn -> true end)
      |> assign_new(:route_path, fn -> :root_path end)
      |> assign_new(:route_method, fn -> :index end)
      |> assign_new(:limit, fn -> 20 end)}
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

  defp first_page(%{route_path: _route} = assigns) do
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

    assigns = assign(assigns, current_class: current_class, page: page)

    ~H"""
      <.link navigate={"#{@route_path}?page=#{@page}"} class={@current_class}>
        <span class="sr-only">First</span>
        <div class="h-5 w-5 flex items-center justify-center">
          <%= for _n <- [1, 2] do %>
            <svg class="h-5 w-5 -m-2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M12.79 5.23a.75.75 0 01-.02 1.06L8.832 10l3.938 3.71a.75.75 0 11-1.04 1.08l-4.5-4.25a.75.75 0 010-1.08l4.5-4.25a.75.75 0 011.06.02z" clip-rule="evenodd" />
            </svg>
          <% end %>
        </div>
      </.link>
    """
  end

  defp last_page(%{route_path: _route } = assigns) do
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

    assigns = assign(assigns, page: page, current_class: current_class)

    ~H"""
      <.link navigate={"#{@route_path}?page=#{@page}"} class={@current_class}>
        <span class="sr-only">Last</span>
        <div class="h-5 w-5 flex items-center justify-center">
          <%= for _ <- [1, 2] do %>
            <svg class="h-5 w-5 -m-2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z" clip-rule="evenodd" />
            </svg>
          <% end %>
        </div>
      </.link>
    """
  end

  defp prev_page(%{route_path: _route, limit: _limit} = assigns) do
    %{meta: %{upstream: upstream, current: current}} = assigns
    base_class = "relative inline-flex items-center px-2 py-2 text-sm font-medium text-gray-500 border-l border-gray-300"

    current_class = case upstream do
      false -> base_class <> " bg-gray-50 cursor-not-allowed"
      _ -> base_class <> " hover:bg-gray-50"
    end

    expected_page = case upstream do
      false -> current
      _ -> current - 1
    end

    assigns = assign(assigns, expected_page: expected_page, current_class: current_class)

    ~H"""
      <.link navigate={"#{@route_path}?page=#{@expected_page}"} class={@current_class}>
        <span class="sr-only">Previous</span>
        <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
          <path fill-rule="evenodd" d="M12.79 5.23a.75.75 0 01-.02 1.06L8.832 10l3.938 3.71a.75.75 0 11-1.04 1.08l-4.5-4.25a.75.75 0 010-1.08l4.5-4.25a.75.75 0 011.06.02z" clip-rule="evenodd" />
        </svg>
      </.link>
    """
  end

  defp next_page(%{route_path: _route, limit: limit} = assigns) do
    %{meta: %{total: total, current: current}} = assigns
    base_class = "relative inline-flex items-center px-2 py-2 text-sm font-medium text-gray-500 border-l border-gray-300"
    has_next_page? = Kernel.>(total, limit * current)

    current_class = case has_next_page? do
      false -> base_class <> " bg-gray-50 cursor-not-allowed"
      _ -> base_class <> " hover:bg-gray-50"
    end

    expected_page = case has_next_page? do
      false -> current
      _ -> current + 1
    end

    assigns = assign(assigns, expected_page: expected_page, current_class: current_class)

    ~H"""
      <.link navigate={"#{@route_path}?page=#{@expected_page}"} class={@current_class}>
        <span class="sr-only">Next</span>
        <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
          <path fill-rule="evenodd" d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z" clip-rule="evenodd" />
        </svg>
      </.link>
    """
  end

  def paginate_value(%{meta: %{total: page}, limit: limit} = assigns) when page > limit do
    lim = Kernel.div(page, limit)
    num = case Kernel.rem(page, limit) do
      0 -> lim
      _ -> lim + 1
    end
    assigns = assign(assigns, num: num, limit: lim)

    ~H"""
      <%= for i <- 1..@num do %>
        <.paginate_child number={i}, active={@current == i} route_path={@route_path} route_method={@route_method} />
      <% end %>
    """
  end
  def paginate_value(%{meta: %{start: start}} = assigns) when start == 0, do: paginate_child(%{assigns | number: 1, active: false})
  def paginate_value(assigns), do: paginate_child(%{assigns | number: 1, active: true})

  def paginate_child(%{number: number, active: active, route_path: _route, route_method: _method} = assigns) when number != 0 do
    current_class = decide_active_class(active)
    assigns = assign(assigns, current_class: current_class)

    ~H"""
      <.link navigate={"#{@route_path}?page=#{@number}"} class={@current_class}><%= @number %></.link>
    """
  end
  def paginate_child(%{active: active} = assigns) do
    assigns = assign(assigns, current_class: decide_active_class(active))

    ~H"""
      <.link href="#" class={@current_class}>...</.link>
    """
  end

  defp decide_active_class(true), do: "relative z-10 inline-flex items-center border border-indigo-500 bg-indigo-50 px-4 py-2 text-sm font-medium text-indigo-600 focus:z-20"
  defp decide_active_class(_), do: "relative inline-flex items-center border border-gray-300 px-4 py-2 text-sm font-medium text-gray-500 hover:bg-gray-50 focus:z-20"
end
