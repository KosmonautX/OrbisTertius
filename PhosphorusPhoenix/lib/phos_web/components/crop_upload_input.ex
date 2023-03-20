defmodule PhosWeb.Components.CropUploadInput do
  use PhosWeb, :live_component

  def render(assigns) do
    ~H"""
    <div id={@id}>
      <%= for entry <- @uploads.image.entries do %>
        <.modal
          id={@id <> "-modal"}
          show={true}
          on_cancel={JS.push("close-modal")}
          on_confirm={JS.push("close-and-select")}
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
              aria-label="cancel">
              &times;
            </button>
          </article>
          <.button type="submit" phx-disable-with="Saving...">Save</.button>
        </.modal>
      <% end %>
    </div>
    """
  end
end
