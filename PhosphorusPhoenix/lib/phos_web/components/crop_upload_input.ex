defmodule PhosWeb.Components.CropUploadInput do
  use PhosWeb, :live_component

  defp random_id, do: "edit"

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
            <div :for={err <- upload_errors(@uploaded.image, entry)} class="alert alert-danger">
              <%= error_to_string(err) %>
            </div>
          </article>
          <.button type="submit" phx-disable-with="Saving...">Save</.button>
        </.modal>
      <% end %>
    </div>
    """
  end

  def handle_event("close-modal", _, socket), do: {:noreply, assign(socket, show_modal: false)}
  defp error_to_string(:too_large), do: "Image too large choose another one"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
end
