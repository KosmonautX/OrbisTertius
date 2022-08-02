defmodule PhosWeb.Components.Loading do
  use PhosWeb, :live_component

  @impl true
  def mount(socket), do: {:ok, socket}

  @impl true
  def render(%{loading: true} = assigns) do
    ~H"""
    <div class="w-full flex items-center justify-center py-4 mt-4 flex-col">
      <i class="fa fa-spinner fa-spin" style="font-size:24px"></i>
      <%= if Map.get(assigns, :text) do %>
        <h3 class="text-gray-500 italic mt-2 text-md"><%= @text %></h3>
      <% end %>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="hidden" />
    """
  end
end
