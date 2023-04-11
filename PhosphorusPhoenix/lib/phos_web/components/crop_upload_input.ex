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
              aria-label="cancel"
            >
              &times;
            </button>
                <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
            <%= for err <- upload_errors(@uploads.image, entry) do %>
              <p class="alert alert-danger"><%= error_to_string(err) %></p>
            <% end %>

          </article>

          <%= for err <- upload_errors(@uploads.image) do %>
            <p class="alert alert-danger"><%= error_to_string(err) %></p>
          <% end %>

          <.button type="submit" phx-disable-with="Saving...">Save</.button>
        </.modal>
      <% end %>
    </div>
    """
  end

  defp error_to_string(:too_large), do: "Image too large choose another one"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
