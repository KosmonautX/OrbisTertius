defmodule Phos.TeleBot do
  use Supervisor

  def start_link(opts) do
    :ok = Phos.TeleBot.Config.load()
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    token = case ExGram.Config.get(:ex_gram, :token) do
      {module, func, env} -> apply(module, func, [env])
      data -> data
    end

    children  = [
    {Phos.TeleBot.Core, [method: :webhook, token: token]},
    # StateManager,
    Phos.TeleBot.Cache,
    Phos.TeleBot.TelegramNotification]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
