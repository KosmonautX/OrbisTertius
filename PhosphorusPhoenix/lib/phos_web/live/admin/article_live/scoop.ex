defmodule PhosWeb.Admin.ArticleLive.Scoop do
  use PhosWeb, :admin_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(_params, _uri, socket) do
    Process.send_after(self(), :fetch, 500)
    {:noreply, assign(socket, scoops: [])}
  end

  @impl true
  def handle_info(:fetch, %{assigns: %{scoops: [_ | _] = _data}} = socket), do: {:noreply, socket}

  @impl true
  def handle_info(:fetch, socket) do
    scoops = Phos.Article.article_tits()
    {:noreply, assign(socket, scoops: scoops)}
  end

  def deadline_status(data) when is_map(data), do: Map.get(data, "start")
  def deadline_status(_), do: "-"
end
