defmodule Phos.TeleBot.TelegramNotification do
  use Supervisor

  alias __MODULE__.{Collector, Dispatcher, Pusher}


  @moduledoc """
  """

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    number    = Keyword.get(config(), :worker, 8)
    workers   = Enum.map(1..number, fn n -> Supervisor.child_spec({Pusher, []}, id: :"telegram_notification_worker_#{n}") end)
    children  = [Collector, Dispatcher, Pusher | workers]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def config() do
    Application.get_env(:phos, __MODULE__, [])
  end

  # @spec notify(t(), option :: Keyword.t()) :: :ok | :error
  # def notify(data, options \\ []), do: Collector.notify(data, options)
end
