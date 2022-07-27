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
    ~H"""
    <div class="flex items-center justify-center fixed inset-0 bg-black/50 z-30">
      <div class="relative w-10/12 md:w-8/12 xl:w-1/2">
        <div class="absolute top-2 right-2">
          <i class="fa-solid fa-xmark cursor-pointer" phx-click={onClose(assigns)} phx-target={onCloseTarget(assigns)}></i>
        </div>
        <.live_component module={PhosWeb.Components.Card} title={@title} id={"modal_for_#{@title}"}>
          <%= render_slot(@inner_block) %>
        </.live_component>
      </div>
    </div>
    """
  end

  defp onClose(%{onClose: event}), do: event
  defp onClose(_), do: "close-modal-for-myself"

  defp onCloseTarget(%{onClose: _event}), do: nil
  defp onCloseTarget(%{myself: target}), do: target
end
