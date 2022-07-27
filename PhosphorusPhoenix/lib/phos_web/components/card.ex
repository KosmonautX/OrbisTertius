defmodule PhosWeb.Components.Card do
  use PhosWeb, :live_component

  @impl true
  def mount(socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div class={"flex flex-col min-w-0 break-words w-full mb-6 shadow-lg rounded #{background(assigns)}"}>
      <div class="rounded-t mb-0 px-4 py-3 border-0">
        <h1 class="font-semibold text-lg text-gray-700"><%= @title %></h1>
      </div>
      <div class="block w-full overflow-x-auto">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  def background(%{class: class} = _assigns), do: class
  def background(assigns), do: "bg-white"
end
