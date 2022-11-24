defmodule PhosWeb.Menshen.Mounter do
  import Phoenix.Component

   @moduledoc """
  Supporting Mounting of distinct User Flows applied to all LiveViews attaching this hook.
  """
  import Phoenix.LiveView
  import Phoenix.Component


  def on_mount(:pleb, _params, %{"user_token" => token}, socket) do
    user =  Map.from_struct(Phos.Users.get_user_by_session_token(token))
    {:cont, assign(socket, :guest, false) |> assign(:current_user, user)}
  end

  def on_mount(:pleb, _params, _session, socket) do
    {:cont, socket |> assign(:guest, true) |> assign(:current_user, nil)}
  end

  def on_mount(:admin, _params, _session, socket) do
    {:cont, assign(socket, :page_title, "AdminWorld")}
  end



end
