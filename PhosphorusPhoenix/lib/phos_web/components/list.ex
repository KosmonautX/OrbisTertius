defmodule PhosWeb.Components.List do
  use PhosWeb, :live_component

  @impl true
  def mount(socket), do: {:ok, socket}

  @impl true
  def update(%{editable: true} = assigns, socket) do
    {:ok, socket
    |> assign(class: Map.get(assigns, :class, view_class()))
    |> assign(disabled: Map.get(assigns, :disabled, true))
    |> assign(assigns)}
  end

  @impl true
  def update(assigns, socket), do: {:ok, assign(socket, assigns)}

  @impl true
  def render(assigns) do
    if (Map.get(assigns, :value) != nil) do
      ~H"""
      <div class="w-full flex items-center justify-between px-4 py-2 border-b">
        <div class="w-1/2"><%= @name %></div>
        <div class="w-1/2"><%= if(Map.get(assigns, :editable, false), do: editable_value(assigns), else: @value) %></div>
      </div>
      """
    else
      ~H"""
      <div class="w-full flex items-center justify-between px-4 py-2 border-b">
        <div class="w-1/2"><%= @name %></div>
        <div class="w-1/2">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
      """
    end
  end

  @impl true
  def handle_event("edit_value", _params, %{assigns: assigns} = socket) do
    case Map.get(assigns, :disabled) do
      true -> {:noreply, assign(socket, [class: edit_class(), disabled: false])}
      _ -> {:noreply, assign(socket, [class: view_class(), disabled: true])}
    end
  end

  def editable_value(%{value: value, class: class, data: data} = assigns) do
    changeset = Ecto.Changeset.change(data)

    ~H"""
    <.form let={f} for={changeset} phx-submit="update" class="flex w-full">
      <%= text_input f, :value, value: value, class: @class, disabled: @disabled, focus: true %>
      <span phx-click="edit_value" phx-target={@myself} class="h-4 w-4">
        <i class="fa-solid fa-pencil cursor-pointer"></i>
      </span>
    </.form>
    """
  end

  defp view_class do
    "border-0 p-0 disabled overflow-none w-full"
  end

  defp edit_class do
    "border-0 border-b p-0 overflow-none w-full py-1"
  end
end
