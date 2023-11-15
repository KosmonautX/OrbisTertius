defmodule PhosWeb.Admin.ArticleLive.ScoopDetail do
  use PhosWeb, :admin_view

  @impl true
  def handle_params(%{"id" => scoop_id}, _uri, socket) do
    data = Phos.Article.article_blocks(scoop_id)
    {:noreply, assign(socket, scoop: Earmark.as_html!(data))}
  end
end
