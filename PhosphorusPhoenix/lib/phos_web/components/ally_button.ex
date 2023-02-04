defmodule PhosWeb.AllyButton do
  use PhosWeb, :live_component

  def update(%{current_user: curr, user: user} = assigns, socket) do
    {:ok, 
      assign(socket, assigns)
      |> assign_new(:self, fn ->
        case Map.get(assigns.current_user, :id) do
          nil -> false
          _ -> assigns.user.id == assigns.current_user.id
        end
      end)
      |> assign_new(:ally, fn -> ally_status(Map.get(curr, :id), user.id) end)
    }
  end

  def update(%{root_id: root_id} = _assigns, %{assigns: %{current_user: user}} = socket) do
    ally =
      root_id
      |> Phos.Folk.get_relation!()
      |> ally_status(user.id)
    {:ok, assign(socket, :ally, ally)}
  end

  def update(%{related_users: _} = _assigns, socket), do: {:ok, assign(socket, :ally, false)}

  def handle_event("add_ally", _, %{assigns: %{user: acceptor, current_user: user, socket: foreign_socket}} = socket) do
    case Phos.Folk.add_friend(user.id, acceptor.id) do
      {:ok, %Phos.Users.RelationRoot{} = relation} -> 
        PhosWeb.Endpoint.broadcast_from(foreign_socket.transport_pid, "folks", "add", relation.id)
        
        {:noreply, 
          socket
          |> put_flash(:info, "Ally request sent!")
          |> assign(:ally, "requested")}
      _ -> {:noreply, socket}
    end
  end

  def handle_event("delete_ally_request", _, %{assigns: %{current_user: user, user: acceptor, socket: foreign_socket}} = socket) do
    with %Phos.Users.RelationBranch{root: root} <- Phos.Folk.get_relation_by_pair(user.id, acceptor.id),
         {:ok, _rel} <- Phos.Folk.delete_relation(root) do
      PhosWeb.Endpoint.broadcast_from(foreign_socket.transport_pid, "folks", "delete", {user.id, acceptor.id})
      {:noreply, 
        socket
        |> assign(ally: false)
        |> put_flash(:danger, "Ally request deleted")}
    else
      {:error, changeset} ->
        {:noreply, 
          Enum.reduce(changeset.errors, socket, fn soc, {field, error} ->
            put_flash(soc, :error, to_string(field) <> " " <> translate_error(error))
          end)}
      _ -> {:noreply, socket}
    end
  end

  def handle_event("reject_ally_request", _, %{assigns: %{current_user: curr, user: user}} = socket) do
    with %Phos.Users.RelationBranch{root: root} <- Phos.Folk.get_relation_by_pair(curr.id, user.id),
         true <- root.acceptor_id == curr.id,
         {:ok, _rel} <- Phos.Folk.update_relation(root, %{"state" => "blocked"}) do
      PhosWeb.Endpoint.broadcast_from(self(), "folks", "reject", root.id)
      {:noreply, 
        socket
        |> put_flash(:danger, "Success rejecting ally")
        |> assign(:ally, ally_status(root, curr.id))}
    else
      {:error, changeset} ->
        {:noreply, 
          Enum.reduce(changeset.errors, socket, fn soc, {field, error} ->
            put_flash(soc, :error, to_string(field) <> " " <> translate_error(error))
          end)}
      false -> {:noreply, put_flash(socket, :error, "Only acceptor can reject ally request")}
      _ -> {:noreply, socket}
    end
  end

  def handle_event("accept_ally_request", _, %{assigns: %{current_user: curr, user: user}} = socket) do
    with %Phos.Users.RelationBranch{root: root} <- Phos.Folk.get_relation_by_pair(curr.id, user.id),
         true <- root.acceptor_id == curr.id,
         {:ok, _rel} <- Phos.Folk.update_relation(root, %{"state" => "completed"}) do
      PhosWeb.Endpoint.broadcast_from(self(), "folks", "accept", root.id)
      {:noreply, 
        socket
        |> put_flash(:info, "Success accepting ally")
        |> assign(:ally, ally_status(root, curr.id))}
    else
      {:error, changeset} ->
        {:noreply, 
          Enum.reduce(changeset.errors, socket, fn soc, {field, error} ->
            put_flash(soc, :error, to_string(field) <> " " <> translate_error(error))
          end)}
      false -> {:noreply, put_flash(socket, :error, "Only acceptor can reject ally request")}
      _ -> {:noreply, socket}
    end
  end

  def render(%{current_user: user} = assigns) when user in [nil, ""] do
    ~H"""
    <div class="flex">
      <.button class="flex items-center p-0 items-start align-center"
        phx-click={show_welcome_message("welcome_message")}>
        <Heroicons.plus class="mr-2 -ml-1 md:w-6 md:h-6 w-4 h-4 " />
        <span>Ally</span>
      </.button>
    </div>
    """
  end

  def render(%{ally: false, self: true} = assigns) do
    ~H"""
    <div class="flex hidden">
      <.button class="hidden">
        button
      </.button>
    </div>
    """
  end

  def render(%{ally: false} = assigns) do
    ~H"""
    <div class="flex">
      <.button class="flex items-center p-0 items-start align-center"
        phx-target={@myself}
        phx-click="add_ally">
        <Heroicons.plus class="mr-2 -ml-1 md:w-6 md:h-6 w-4 h-4 " />
        <span>Ally</span>
      </.button>
    </div>
    """
  end

  def render(%{ally: ally} = assigns) when ally == "requested"  do
    ~H"""
    <div class="flex">
      <.button class="flex items-center p-0 items-start align-center"
        phx-click={show_modal("delete_friend_request_#{@user.id}")}>
        <span><%= String.capitalize(@ally) %></span>
      </.button>
      <.modal id={"delete_friend_request_#{@user.id}"} on_confirm={JS.push("delete_ally_request", target: @myself) |> hide_modal("delete_friend_request")}>
        <:title>Delete friend request confirmation ?</:title>
        <div>
          Are you sure want to delete your friend request to <%= @user.username %> ?
        </div>
        <:confirm tone={:danger}>Yes, delete</:confirm>
        <:cancel>No, keep requesting</:cancel>
      </.modal>
    </div>
    """
  end

  def render(%{ally: ally} = assigns) when ally == "requesting"  do
    ~H"""
    <div class="flex">
      <.button tone={:success}
        phx-target={@myself}
        phx-click="accept_ally_request"
        class="flex items-center p-0 items-start align-center">
        <span>Accept</span>
      </.button>
      <.button tone={:dark}
        phx-target={@myself}
        phx-click="reject_ally_request"
        class="flex items-center p-0 items-start align-center ml-2">
        <span>Reject</span>
      </.button>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="flex">
      <.button class="flex items-center p-0 items-start align-center"
        phx-target={@myself}
        tone={if(@ally == "completed", do: :warning, else: :primary)}
        phx-click="add_ally">
        <span class="capitalize"><%= if(@ally == "completed", do: "Chat", else: @ally) %></span>
      </.button>
    </div>
    """
  end

  defp ally_status(%Phos.Users.RelationBranch{root: root}, user_id), do: ally_status(root, user_id)
  defp ally_status(%Phos.Users.RelationRoot{acceptor_id: acc_id, state: state} = _root, user_id) when acc_id == user_id do
    case state do
      "requested" -> "requesting"
      _ -> state
    end
  end
  defp ally_status(%Phos.Users.RelationRoot{} = root, _user_id), do: root.state
  defp ally_status(user_id, acceptor_id) when is_bitstring(user_id) and is_bitstring(acceptor_id) do
    case Phos.Folk.get_relation_by_pair(user_id, acceptor_id) do
      %Phos.Users.RelationBranch{} = data -> 
        ally_status(data, user_id)
      _ -> ally_status(nil, nil)
    end
  end
  defp ally_status(_, _), do: false
end
