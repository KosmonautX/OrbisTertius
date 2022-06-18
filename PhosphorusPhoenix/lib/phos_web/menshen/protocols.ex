defmodule PhosWeb.Menshen.Protocols do

   @moduledoc """
  Supporting Mounting of distinct User Flows applied to all LiveViews attaching this hook.
  """
  import Phoenix.LiveView


  def on_mount(:pleb, params, %{"current_user" => %Phos.Users.User{} = user}, socket) do
    {:cont, assign(socket, :current_user, user)}
  end


  def on_mount(:pleb, params, _session, socket) do
    {:cont, assign(socket, :guest, true) |> assign(:current_user, %{username: Neighbour})
    }
  end

  def on_mount(:admin, _params, _session, socket) do
    {:cont, assign(socket, :page_title, "AdminWorld")}
  end



end
