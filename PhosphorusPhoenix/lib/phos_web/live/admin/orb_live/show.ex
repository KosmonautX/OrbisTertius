defmodule PhosWeb.Admin.OrbLive.Show do
  use PhosWeb, :admin_view

  alias Phos.Action

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    case Action.get_orb(id) do
      {:ok, orb} -> {:ok, assign(socket, orb: orb, traits_form: [], changeset: Ecto.Changeset.change(orb))}
      _ -> {:ok, assign(socket, :orb, nil)}
    end
  end

  def update_title(resource, %{"orb" => %{"value" => title}}) do
    Action.update_orb(resource, %{title: title})
  end

  @impl true
  def handle_event("take-down", _params, %{assigns: %{orb: orb}} = socket) do
    case Action.update_orb(orb, %{active: false}) do
      {:ok, orb} ->
        {:noreply, socket
        |> assign(orb: orb)
        |> put_flash(:info, "orb status updated.")}
      _ ->
        {:noreply, socket
        |> put_flash(:error, "orb status failed to update")}
    end
  end

  @impl true
  def handle_event("trait_management", %{"method" => "delete", "id" => id} = params, %{assigns: %{traits_form: val}} = socket) do
    index = String.to_integer(id)
    {:noreply, assign(socket, [traits_form: List.delete_at(val, index)])}
  end

  @impl true
  def handle_event("trait_management", %{"method" => "add"}, %{assigns: %{traits_form: val}} = socket) do
    {:noreply, assign(socket, [traits_form: val ++ [""]])}
  end

  @impl true
  def handle_event("trait_management", _params, socket) do
    {:noreply, assign(socket, [traits_form: [""]])}
  end

  @impl true
  def handle_event("trait_change", %{"orb" => trait_change} = _params, socket) do
    traits = Map.values(trait_change)
    {:noreply, assign(socket, :traits_form, traits)}
  end

  @impl true
  def handle_event("save_trait", %{"orb" => trait_change} = _params, %{assigns: %{orb: orb}} = socket) do
    traits = Map.values(trait_change)
    case Action.update_orb(orb, %{traits: orb.traits ++ traits}) do
      {:ok, orb} ->
        {:noreply, socket
        |> assign([orb: orb, traits_form: [], changeset: Ecto.Changeset.change(orb)])
        |> put_flash(:info, "orb traits updated.")}
      _ ->
        {:noreply, socket
        |> put_flash(:error, "orb traits failed to update")}
    end
  end
end
