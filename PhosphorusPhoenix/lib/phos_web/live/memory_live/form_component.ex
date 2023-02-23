defmodule PhosWeb.MemoryLive.FormComponent do
  use PhosWeb, :live_component

  alias Phos.Message

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage memory records in your database.</:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="memory-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={{f, :message}} type="text" label="message" />
        <.input field={{f, :media}} type="checkbox" label="media" />
        <.input field={{f, :user_source_id}} type="hidden" value={@initiator.id}/>
        <.input field={{f, :orb_subject_id}} type="hidden" value={"791313df-6d46-4661-a8e2-04747a75f395"}/>
        <:actions>
          <.button phx-disable-with="Saving..." type="submit" >Save Memory</.button>
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
