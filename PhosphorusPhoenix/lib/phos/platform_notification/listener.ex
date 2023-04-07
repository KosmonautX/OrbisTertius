defmodule Phos.PlatformNotification.Listener do
  use GenServer

  require Logger

  @channel "table_changes"

  def start_link(channel), do: GenServer.start_link(__MODULE__, channel, name: __MODULE__)

  @impl true
  def init(_channel) do
    Logger.info("Starting #{__MODULE__} with channel subscription: #{inspect(@channel)}")

    config = Phos.Repo.config()
    {:ok, pid} = Postgrex.Notifications.start_link(config)
    {:ok, ref} = Postgrex.Notifications.listen(pid, @channel)
    {:ok, {pid, @channel, ref}}
  end

  @impl true
  def handle_info({:notification, _pid, _ref, @channel, payload}, state) do
    changes = Jason.decode!(payload)
    IO.inspect(changes)

    {:noreply, state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}
end
