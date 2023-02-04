defmodule PhosWeb.ReverieLive.FormComponent do
  use PhosWeb, :live_component

  alias Phos.Message

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage reverie records in your database.</:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="reverie-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={{f, :read}} type="datetime-local" label="read" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Reverie</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{reverie: reverie} = assigns, socket) do
    changeset = Message.change_reverie(reverie)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"reverie" => reverie_params}, socket) do
    changeset =
      socket.assigns.reverie
      |> Message.change_reverie(reverie_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"reverie" => reverie_params}, socket) do
    save_reverie(socket, socket.assigns.action, reverie_params)
  end

  defp save_reverie(socket, :edit, reverie_params) do
    case Message.update_reverie(socket.assigns.reverie, reverie_params) do
      {:ok, _reverie} ->
        {:noreply,
         socket
         |> put_flash(:info, "Reverie updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_reverie(socket, :new, reverie_params) do
    case Message.create_reverie(reverie_params) do
      {:ok, _reverie} ->
        {:noreply,
         socket
         |> put_flash(:info, "Reverie created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
