defmodule PhosWeb.Admin.NotificationLive.Index do
  use PhosWeb, :admin_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(_unsigned_params, _uri, socket) do
    notifications = Phos.Notification.Scheduller.list()
    pid = self()
    spawn(fn ->
      case notifications do
        [] ->
          Phos.Notification.Scheduller.renew()
          Process.send_after(pid, :refresh, 100)
        _ -> :ok
      end
    end)
    {:noreply, assign(socket, notifications: notifications)}
  end

  def handle_info(:refresh, socket) do
    notifications = Phos.Notification.Scheduller.list()
    {:noreply, assign(socket, notifications: notifications)}
  end

  def handle_event("execute", %{"id" => id}, socket) do
    Phos.Notification.Scheduller.execute(id)
    {:noreply, put_flash(socket, :info, "Notification with hash #{String.slice(id, 0..6)} was executed")}
  end
end
