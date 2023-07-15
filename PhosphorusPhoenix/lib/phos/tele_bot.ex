defmodule Phos.TeleBot do
  use Supervisor
  alias __MODULE__.{StateManager, TelegramNotification}
  alias Phos.TeleBot.Core, as: BotCore

  alias Phos.Repo

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    token = case ExGram.Config.get(:ex_gram, :token) do
      {module, func, env} -> apply(module, func, [env])
      data -> data
    end

    children  = [
    {BotCore, [method: :webhook, token: token]},
    StateManager,
    TelegramNotification]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
