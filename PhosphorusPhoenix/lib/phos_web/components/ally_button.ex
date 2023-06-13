defmodule PhosWeb.Component.AllyButton do
  use PhosWeb, :live_component
  import PhosWeb.SVG

  defp random_id, do: Enum.random(1..1_000_000)

  def update(
        %{current_user: curr, user: user, parent_pid: parent_pid} = assigns,
        socket
      )
      when not is_nil(curr) do
    {:ok,
     socket
     |> assign_new(:self, fn ->
       case Map.get(curr, :id) do
         nil -> false
         _ -> assigns.user.id == assigns.current_user.id
       end
     end)
     |> assign_new(:ally, fn ->
       ally_status(Map.get(curr, :id), user.id)
     end)
     |> assign_new(:parent_pid, fn -> parent_pid end)
     |> assign_new(:size, fn -> Map.get(assigns, :size, nil) end)
     |> assign_new(:user, fn -> user end)
     |> assign_new(:current_user, fn -> curr end)}
  end

  def update(
        %{root_id: root_id} = _assigns,
        %{assigns: %{current_user: user}} = socket
      ) do
    rel = Phos.Folk.get_relation!(root_id)
    ally = rel |> ally_status(user.id)

    {:ok,
     socket
     |> assign(:ally, ally)
     |> assign(:rel, rel)}
  end

  def update(
        _,
        %{
          assigns: %{current_user: user, user: acceptor, parent_pid: parent_pid}
        } = socket
      ) do
    {:ok, assign(socket, ally: false, current_user: user)}
  end

  def update(assigns, socket) do
    {:ok,
     assign(socket,
       ally: false,
       current_user: nil,
       size: Map.get(assigns, :size, nil)
     )}
  end

  def handle_event(
        "add_ally",
        _,
        %{
          assigns: %{user: acceptor, current_user: user, parent_pid: parent_pid}
        } = socket
      ) do
    case Phos.Folk.add_friend(user.id, acceptor.id) do
      {:ok, %Phos.Users.RelationRoot{} = relation} ->
        PhosWeb.Endpoint.broadcast_from(parent_pid, "folks", "add", relation.id)

        {:noreply,
         socket
         |> put_flash(:info, "Ally request sent!")
         |> assign(:ally, "requested")}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event(
        "delete_ally_request",
        _,
        %{
          assigns: %{current_user: user, user: acceptor, parent_pid: parent_pid}
        } = socket
      ) do
    with %Phos.Users.RelationBranch{root: root} <-
           Phos.Folk.get_relation_by_pair(user.id, acceptor.id),
         {:ok, _rel} <- Phos.Folk.delete_relation(root) do
      PhosWeb.Endpoint.broadcast_from(
        parent_pid,
        "folks",
        "delete",
        {user.id, acceptor.id}
      )

      {:noreply,
       socket
       |> assign(ally: false)
       |> put_flash(:danger, "Ally request deleted")}
    else
      {:error, changeset} ->
        {:noreply,
         Enum.reduce(changeset.errors, socket, fn soc, {field, error} ->
           put_flash(
             soc,
             :error,
             to_string(field) <> " " <> translate_error(error)
           )
         end)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event(
        "reject_ally_request",
        _,
        %{assigns: %{current_user: curr, user: user}} = socket
      ) do
    with %Phos.Users.RelationBranch{root: root} <-
           Phos.Folk.get_relation_by_pair(curr.id, user.id),
         true <- root.acceptor_id == curr.id,
         {:ok, _rel} <- Phos.Folk.delete_relation(root) do
      PhosWeb.Endpoint.broadcast_from(self(), "folks", "reject", root.id)

      {:noreply,
       socket
       |> put_flash(:danger, "Success rejecting ally")
       |> assign(:ally, ally_status(root, curr.id))}
    else
      {:error, changeset} ->
        {:noreply,
         Enum.reduce(changeset.errors, socket, fn soc, {field, error} ->
           put_flash(
             soc,
             :error,
             to_string(field) <> " " <> translate_error(error)
           )
         end)}

      false ->
        {:noreply,
         put_flash(socket, :error, "Only acceptor can reject ally request")}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event(
        "accept_ally_request",
        _,
        %{assigns: %{current_user: curr, user: user}} = socket
      ) do
    with %Phos.Users.RelationBranch{root: root} <-
           Phos.Folk.get_relation_by_pair(curr.id, user.id),
         true <- root.acceptor_id == curr.id,
         {:ok, _rel} <-
           Phos.Folk.update_relation(root, %{"state" => "completed"}) do
      PhosWeb.Endpoint.broadcast_from(self(), "folks", "accept", root.id)

      {:noreply,
       socket
       |> put_flash(:info, "Success accepting ally")
       |> assign(:ally, ally_status(root, curr.id))}
    else
      {:error, changeset} ->
        {:noreply,
         Enum.reduce(changeset.errors, socket, fn soc, {field, error} ->
           put_flash(
             soc,
             :error,
             to_string(field) <> " " <> translate_error(error)
           )
         end)}

      false ->
        {:noreply,
         put_flash(socket, :error, "Only acceptor can reject ally request")}

      _ ->
        {:noreply, socket}
    end
  end

  def render(%{current_user: user, size: "small"} = assigns)
      when user in [nil, ""] do
    ~H"""
    <a class="flex" phx-click={show_modal("welcome_message")}>
      <.ally_btn />
    </a>
    """
  end

  def render(%{current_user: user} = assigns)
      when user in [nil, ""] do
    ~H"""
    <a class="flex" phx-click={show_modal("welcome_message")}>
     <.plus_btn />
    </a>
    """
  end

  def render(%{ally: false, self: true} = assigns) do
    ~H"""
    <a class="flex hidden">
      <.button class="hidden">
        button
      </.button>
    </a>
    """
  end

  def render(%{ally: "completed", user: user} = assigns) do
    ~H"""
    <a class="flex">
      <.link navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/memories/user/#{user.username}")}>
        <Heroicons.paper_airplane class="lg:w-8 lg:h-8 w-6 h-6 dark:text-white font-semibold" />
      </.link>
    </a>
    """
  end

  def render(%{ally: ally} = assigns)
      when ally == "requested" or ally == "blocked" do
    assigns =
      assigns
      |> assign(
        :dom_id,
        "delete_friend_request_#{random_id()}_#{assigns.user.id}"
      )

    ~H"""
    <a class="flex">
      <.button class="flex" phx-click={show_modal(@dom_id)}>
        <%= String.capitalize(@ally) %>
      </.button>
      <.modal
        id={@dom_id}
        on_confirm={
          JS.push("delete_ally_request", target: @myself) |> hide_modal("delete_friend_request")
        }
      >
        <:title>Unally?</:title>
        <a>
          Are you sure want to delete your request to <%= @user.username %> ?
        </a>
        <:confirm tone={:danger}>Yes, delete</:confirm>
        <:cancel>No, keep requesting</:cancel>
      </.modal>
    </a>
    """
  end

  def render(%{ally: ally} = assigns) when ally == "requesting" do
    ~H"""
    <a class="flex gap-2">
      <button
        phx-target={@myself}
        phx-click="accept_ally_request"
        type="button"
        class="text-white bg-[#9747FF] hover:bg-purple-300 focus:outline-none focus:ring-4 focus:ring-teal-300 font-bold rounded-2xl lg:text-base px-5 py-2.5 text-center dark:focus:ring-teal-900 font-poppins"
      >
        Accept
      </button>
      <button
        phx-target={@myself}
        phx-click="reject_ally_request"
        type="button"
        class="text-white bg-[#9747FF] hover:bg-purple-300 focus:outline-none focus:ring-4 focus:ring-teal-300 font-bold rounded-2xl lg:text-base px-5 py-2.5 text-center dark:focus:ring-teal-900 font-poppins"
      >
        Reject
      </button>
    </a>
    """
  end

  def render(%{ally: false} = assigns) do
    ~H"""
    <a phx-target={@myself} phx-click="add_ally">
      <.plus_btn />
    </a>
    """
  end

  def render(assigns) do
    ~H"""
    <a class="flex">
      <.button class="flex capitalize" tone={:primary}>
        <%= @ally %>
      </.button>
    </a>
    """
  end

  defp ally_status(%Phos.Users.RelationBranch{root: root}, user_id),
    do: ally_status(root, user_id)

  defp ally_status(
         %Phos.Users.RelationRoot{acceptor_id: acc_id, state: state} = _root,
         user_id
       )
       when acc_id == user_id do
    case state do
      "requested" -> "requesting"
      _ -> state
    end
  end

  defp ally_status(%Phos.Users.RelationRoot{} = root, _user_id), do: root.state

  defp ally_status(user_id, acceptor_id)
       when is_bitstring(user_id) and is_bitstring(acceptor_id) do
    case Phos.Folk.get_relation_by_pair(user_id, acceptor_id) do
      %Phos.Users.RelationBranch{} = data ->
        ally_status(data, user_id)

      _ ->
        ally_status(nil, nil)
    end
  end

  defp ally_status(_, _), do: false
end
