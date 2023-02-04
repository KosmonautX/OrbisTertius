defmodule Phos.Notification.Poller do
  use DynamicSupervisor

  def start_link(opts) do
    {:ok, pid} = DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
    spec = {Phos.Notification.Subscriber, opts}
    worker = Application.get_env(:phos, Phos.Notification, []) |> Keyword.get(:worker, 5)
    Enum.each(1..worker, fn _ ->
      DynamicSupervisor.start_child(pid, spec)
    end)

    {:ok, pid}
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(opts) do
    spec = {Phos.Notification.Subscriber, opts}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
