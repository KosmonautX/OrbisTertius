defmodule PhosWeb.Components.TraitsInput do
  use PhosWeb, :live_component


  @impl true
  def update(%{traits: traits, changeset: changeset} = assigns, socket) do
    {:ok,
     socket
     |> assign_new(:changeset, fn -> changeset end)
     |> assign_new(:traits, fn -> traits end)
     |> assign(:entity, assigns.entity)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full p-2 mt-4">
      <.card title="Edit Orb Traits">
      <div class="px-4 py-2">
      <.form
      :let={f}
      for={@changeset}
      :if={length(@traits) > 0}
      phx-change="trait_change"
      phx-submit="save_trait"
      phx-target={@myself}
      id="traits_form"
      >
      <div>
      <button
      type="button"
      phx-click="trait_management"
      phx-target={@myself}
      phx-value-method="add"
      class="ml-2 button button-sm"
      id="button_add_trait_orb"
      >
      <i class="fa-solid fa-plus cursor-pointer mr-1"></i> Edit trait(s)
      </button>
      </div>
      <%= for {val, index} <- Enum.with_index(@traits) do %>
        <div class="flex mt-1 items-center" id={"trait_orb_list_#{index}"}>
          <%= text_input(f, :"trait[#{index}]",
            value: val,
            required: true,
            id: "trait_orb_input_#{index}",
            class: "text-sm px-2 py-1 border-0 border-b"
          ) %>
          <i
            class="fa-solid fa-trash ml-1 hover:text-red-300 cursor-pointer"
            phx-click="trait_management"
            phx-target={@myself}
            phx-value-method="delete"
            phx-value-id={index}
            id={"traits_delete_icon_#{index}"}
          >
          </i>
        </div>
      <% end %>
      <div class="mt-4">
        <%= submit("save trait(s)", class: "button button-sm") %>
      </div>
      </.form>
      <button
        :if={length(@traits) <= 0}
        type="button"
        phx-click="trait_management"
        phx-target={@myself}
        phx-value-method="init"
        class="button button-sm"
      >
        <i class="fa-solid fa-plus cursor-pointer mr-1"></i> Add trait
      </button>
    </div>
    </.card>
    </div>
    """
  end

  @impl true
  def handle_event(
        "trait_management",
        %{"method" => "delete", "id" => id} = _params,
        %{assigns: %{traits: val}} = socket
      ) do
    index = String.to_integer(id)
    {:noreply, assign(socket, traits: List.delete_at(val, index))}
  end

  @impl true
  def handle_event(
        "trait_management",
        %{"method" => "add"},
        %{assigns: %{traits: val}} = socket
      ) do
    {:noreply, assign(socket, traits: val ++ [""])}
  end

  @impl true
  def handle_event("trait_management", _params, socket) do
    {:noreply, assign(socket, traits: [""])}
  end

  @impl true
  def handle_event("trait_change", %{"orb" => trait_change} = _params, socket) do
    traits = Map.values(trait_change)
    {:noreply, assign(socket, :traits, traits)}
  end

  def handle_event("trait_change", %{"_target" => [hd | _target]} = params, socket) do
    traits = Map.values(Map.get(params, hd, %{}))
    {:noreply, assign(socket, :traits, traits)}
  end

  @impl true
  def handle_event(
        "save_trait",
        %{"orb" => traits},
      %{assigns: %{entity: %Phos.Action.Orb{} = orb}} = socket
      ) do
    traits = Map.values(traits)

    case Phos.Action.update_admin_orb(orb, %{traits: traits}) do
      {:ok, orb} ->
        {:noreply,
         socket
         |> assign(orb: orb, traits: orb.traits, changeset: Ecto.Changeset.change(orb))
         |> put_flash(:info, "orb traits updated.")}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "orb traits failed to update")}
    end
    #
    {:noreply, assign(socket, :traits, traits)}
  end

  def handle_event(
        "save_trait",
        %{"user" => traits},
      %{assigns: %{entity: %Phos.Users.User{} = user}} = socket
      ) do
    traits = Map.values(traits)

    case Phos.Users.update_user(user, %{public_profile: %{traits: traits}}) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(user: user, traits: user.public_profile.traits, changeset: Ecto.Changeset.change(user))
         |> put_flash(:info, "user traits updated.")}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "user traits failed to update")}
    end

    {:noreply, assign(socket, :traits, traits)}
    end
end
