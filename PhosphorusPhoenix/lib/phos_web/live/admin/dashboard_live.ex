defmodule PhosWeb.Admin.DashboardLive do
  use PhosWeb, :admin_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, socket
      |> assign(:params, params)}
  end
end
