defmodule PhosWeb.Admin.NotificationLive.Index do
  use PhosWeb, :admin_view

  alias Phos.PlatformNotification.Global, as: Notification

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(_unsigned_params, _uri, socket) do
    notifications = Notification.list()
    case notifications do 
      [] -> reload_notification(self())
      _ -> :ok
    end
    {:noreply, assign(socket, notifications: notifications)}
  end

  def handle_info(:refresh, socket) do
    notifications = Notification.list()
    {:noreply, assign(socket, notifications: notifications)}
  end

  def handle_event("renew", %{}, socket) do
    reload_notification(self())
    {:noreply,
     socket
     |> put_flash(:info, "Renewing Notifications")
     |> redirect(to: "/admin/notifications")
    }
  end

  def handle_event("execute", %{"id" => id}, socket) do
    Notification.execute(id)
    {:noreply, put_flash(socket, :info, "Notification with hash #{String.slice(id, 0..6)} was executed")}
  end

  def handle_event("enable", %{"id" => id}, socket) do
    Notification.start(id)
    reload_notification(self())
    {:noreply, put_flash(socket, :info, "Notification with hash #{String.slice(id, 0..6)} started")}
  end

  def handle_event("disable", %{"id" => id}, socket) do
    Notification.stop(id)
    reload_notification(self())
    {:noreply, put_flash(socket, :info, "Notification with hash #{String.slice(id, 0..6)} stopped")}
  end

  defp reload_notification(pid) do
    spawn(fn ->
      Notification.renew()
      send(pid, :refresh)
    end)
  end
end
