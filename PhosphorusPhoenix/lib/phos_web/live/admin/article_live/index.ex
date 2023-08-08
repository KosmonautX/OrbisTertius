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
      article_title: "",
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
  def handle_event("create-article", _params, %{assigns: %{selected_orb: orbs}} = socket) do
    IO.inspect(orbs)
    {:noreply, assign(socket, selected_orb: %{})}
  end

  @impl true
  def handle_event("validate-article", %{"article" => %{"title" => title}}, socket) do
    {:noreply, assign(socket, article_title: title)}
  end
end
