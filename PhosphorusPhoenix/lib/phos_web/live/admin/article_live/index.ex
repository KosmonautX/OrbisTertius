defmodule PhosWeb.Admin.ArticleLive.Index do
  use PhosWeb, :admin_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  def article_selector(orbs, id) do
    case Map.get(orbs, id) do
      nil -> "false"
      _ -> "true"
    end
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    %{data: orbs, meta: meta} = Phos.Action.filter_orbs_by_keyword("")
    
    {:noreply, assign(socket,
      existing_articles: [],
      new_article_title: "",
      existing_orbs: [],
      article_title: "",
      article_type: "append",
      selected_orb: %{},
      orbs: orbs,
      search_keyword: "",
      limit: 20,
      current: meta.pagination.current,
      pagination: meta.pagination)}
  end

  @impl true
  def handle_event("select", %{"orb-id" => id, "value" => "true"} = _params, %{assigns: %{selected_orb: selected_orb, orbs: orbs}} = socket) do
    [orb | _] = Enum.filter(orbs, &Kernel.==(&1.id, id))

    {:noreply, assign(socket, :selected_orb, Map.put(selected_orb, id, orb))}
  end

  @impl true
  def handle_event("select", %{"orb-id" => id} = _params, %{assigns: %{selected_orb: orbs}} = socket) do
    remaining_orbs = Enum.reject(orbs, fn {k, _v} -> String.equivalent?(k, id) end) |> Enum.into(%{})
    {:noreply, assign(socket, :selected_orb, remaining_orbs)}
  end

  @impl true
  def handle_event("create-article", params, %{assigns: %{selected_orb: _orbs}} = socket) do
    IO.inspect(params)
    {:noreply, assign(socket, selected_orb: %{})}
  end

  @impl true
  def handle_event("validate-article", %{"_target" => ["existing_article_id"], "existing_article_id" => type}, %{assigns: %{article_type: article_type}} = socket) when type != article_type do
    case type do
      "new" -> {:noreply, assign(socket, :article_type, "new")}
      _ -> 
        ids = Phos.Article.article_orbs(type)
        {:noreply, assign(socket, existing_orbs: Phos.Action.filter_orbs_by_ids(ids), article_type: type)}
    end
  end

  @impl true
  def handle_event("validate-article", %{"article" => %{"search" => title}}, %{assigns: %{article_title: article_title}} = socket) when article_title != title and title != "" do
    existing_articles = Phos.Article.search_article_by_title(title)
    article_type = case length(existing_articles) do
      0 -> "new"
      _ -> "append"
    end
    {:noreply, assign(socket, existing_articles: existing_articles, article_type: article_type)}
  end

  @impl true
  def handle_event("validate-article", %{"article" => %{"title" => title}}, socket), do: {:noreply, assign(socket, article_title: title)}

  @impl true
  def handle_event("validate-article", _params, socket) do
    {:noreply, assign(socket, :article_type, "append")}
  end
end
