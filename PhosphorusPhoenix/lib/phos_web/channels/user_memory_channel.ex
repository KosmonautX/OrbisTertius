defmodule PhosWeb.UserMemoryChannel do
  use PhosWeb, :channel
  alias PhosWeb.Util.Viewer

  def join("memory:user:" <> id, _payload, socket) do
    if authorized?(socket, id) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("memory", {:formation, memory}, socket) do
    broadcast(socket, "memory_formation", memory)
    {:noreply, socket}
  end

  def handle_in("ping", _, socket) do
    {:noreply, socket}
  end

  def handle_in(_anything, payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  def handle_info({Phos.PubSub, {:memory, event}, %Phos.Message.Memory{} = memory}, socket) do
    push(socket, "memory_" <> to_string(event), %{"data" => [memory] |> Viewer.memory_mapper()})
    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    push(socket, "memory_", %{"data" => [msg] |> Viewer.memory_mapper()})
    {:noreply, socket}
  end
end