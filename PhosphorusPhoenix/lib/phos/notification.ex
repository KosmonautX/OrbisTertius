defmodule Phos.Notification do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    children = [
      Phos.Notification.Subcriber
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
