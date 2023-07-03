defmodule PhosWeb.Components.CropUploadInput do
  use PhosWeb, :live_component

  defp random_id, do: Enum.random(1..1_000_000)


  def update(assigns, socket) do
    {:ok, assign(socket,
        id: assigns.id,
        uploaded: assigns.uploads)}
  end

  def render(assigns) do
    ~H"""
    <div id={@id}>
      <%= for entry <- @uploaded.image.entries do %>
        <.modal
          id={@id <> "-modal-#{random_id()}"}
          show={true}
          on_cancel={JS.push("close-modal", target: @myself)}
          on_confirm={JS.push("close-and-select", target: @myself)}
        >
          <:title>Crop Image</:title>
          <article class="upload-entry">
            <figure>
              <.live_img_preview entry={entry} />
              <figcaption><%= entry.client_name %></figcaption>
            </figure>

            <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>

            <button
              type="button"
              phx-click="cancel-upload"
              phx-value-ref={entry.ref}
              aria-label="cancel"
            >
              &times;
            </button>
                <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
            <%= for err <- upload_errors(@uploaded.image, entry) do %>
              <p class="alert alert-danger"><%= error_to_string(err) %></p>
            <% end %>

          </article>

          <%= for err <- upload_errors(@uploaded.image) do %>
            <p class="alert alert-danger"><%= error_to_string(err) %></p>
          <% end %>

          <.button type="submit" phx-disable-with="Saving...">Save</.button>
        </.modal>
      <% end %>
    </div>
    """
  end

  def handle_event("close-modal", _, socket), do: {:noreply, assign(socket, show_modal: false)}
  defp error_to_string(:too_large), do: "Image too large choose another one"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
