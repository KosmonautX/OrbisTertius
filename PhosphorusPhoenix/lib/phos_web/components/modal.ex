defmodule PhosWeb.Components.Modal do
  use PhosWeb, :live_component

  @impl true
  def mount(socket), do: {:ok, socket}

  @impl true
  def handle_event("close-modal-for-myself", _, socket) do
    {:reply, %{event: "close-modal"}, assign(socket, :shown, false)}
  end

  @impl true
  def render(%{shown: false} = assigns) do
    ~H"""
    <div class="hidden" />
    """
  end

  @impl true
  def render(assigns) do
    assigns = assigns
              |> assign_new(:footer, fn -> [] end)

    ~H"""
    <div class="overflow-scroll flex items-start justify-center fixed inset-0 bg-black/50 z-30">
      <div class="h-6/12 w-10/12 md:w-8/12 xl:w-1/2">
        <div class="absolute top-2 right-2">
          <i class="fa-solid fa-xmark cursor-pointer" phx-click={on_close(assigns)} phx-target={on_close_target(assigns)}></i>
        </div>
        <.live_component module={PhosWeb.Components.Card} title={@title} id={"modal_for_#{@title}"}>
          <%= render_slot(@inner_block) %>

          <div class="border-t rounded-b-lg w-full px-3 py-2">
            <%= render_slot(@footer) %>
          </div>
        </.live_component>
      </div>
    </div>
    """
  end

  defp on_close(%{onClose: event}), do: event
  defp on_close(_), do: "close-modal-for-myself"

  defp on_close_target(%{onClose: _event}), do: nil
  defp on_close_target(%{myself: target}), do: target
end
