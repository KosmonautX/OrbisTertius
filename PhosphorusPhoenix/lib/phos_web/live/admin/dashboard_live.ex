defmodule PhosWeb.Admin.DashboardLive do
  use PhosWeb, :admin_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}
end
