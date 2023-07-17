defmodule PhosWeb.LocationMemoryChannel do
  use PhosWeb, :channel

  def join("memory:location:" <> _loc, %{"user_id" => user_id} = _payload, socket) do
    if authorized?(socket, user_id) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("new_message", %{"message" => msg} = params, %{topic: "memory:location:" <> key, assigns: assigns} = socket) do
    broadcast(socket, "#{key}_state", %{
      message: msg,
      reply_from: reply_from(params),
      user: PhosWeb.Util.Viewer.user_mapper(assigns.current_user)
    })
    {:reply, {:ok, "sent"}, socket}
  end

  defp reply_from(%{"reply_from" => %{"user" => user, "message" => message}}), do: %{message: message, user: user}
  defp reply_from(_), do: nil
end
