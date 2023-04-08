defmodule PhosWeb.MemoryLive.FormComponent do
  use PhosWeb, :live_component

  alias Phos.Message

  @impl true
  def render(assigns) do
    ~H"""
    <div class="border-t-2 border-gray-200 px-2 relative">
      <.simple_form
        :let={f}
        class=""
        for={@changeset}
        id="memory-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={{f, :message}} type="text" placeholder="Scratching..." />
        <.input field={{f, :user_source_id}} type="hidden" value={@current_user.id} />
        <.input :if={!is_nil(@rel)} field={{f, :rel_subject_id}} type="hidden" value={@rel.id} />

        <:actions>
          <button type="submit" phx-disable-with="Saving..." class="absolute inset-y-1 right-4">
            <Heroicons.paper_airplane class="h-8 w-8 text-teal-400 font-bold" />
          </button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{memory: memory} = assigns, socket) do
    changeset = Message.change_memory(memory)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"memory" => memory_params}, socket) do
    changeset =
      socket.assigns.memory
      |> Message.change_memory(memory_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"memory" => memory_params}, socket) do
    save_memory(socket, socket.assigns.action, memory_params)
  end

  defp save_memory(socket, :edit, memory_params) do
    case Message.update_memory(socket.assigns.memory, memory_params) do
      {:ok, _memory} ->
        {:noreply,
         socket
         |> put_flash(:info, "Memory updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_memory(socket, :new, memory_params) do
    case Message.create_memory(memory_params |> Map.put("id", Ecto.UUID.generate())) do
      {:ok, _memory} ->
        {:noreply,
         socket
         |> put_flash(:info, "Memory created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end