defmodule PhosWeb.Menshen.Mounter do

   @moduledoc """
  Supporting Mounting of distinct User Flows applied to all LiveViews attaching this hook.
  """
  import Phoenix.LiveView


  def on_mount(:pleb, _params, %{"user_token" => token}, socket) do
    user =  Map.from_struct(Phos.Users.get_user_by_session_token(token))
    {:cont, assign(socket, :guest, false) |>assign(:current_user, user)}
  end

  def on_mount(:pleb, _params, _session, socket) do
    {:cont, assign(socket, :guest, true)}
  end

  def on_mount(:admin, _params, _session, socket) do
    {:cont, assign(socket, :page_title, "AdminWorld")}
  end



end
