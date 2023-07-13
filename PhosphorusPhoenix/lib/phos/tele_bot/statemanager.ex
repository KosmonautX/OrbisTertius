defmodule Phos.TeleBot.StateManager do
  use Agent

  def start_link(_initial_value) do
    :ok = Phos.TeleBot.Config.load()
    {:ok, pid} = Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get_state(user_id) when is_integer(user_id), do: Agent.get(__MODULE__, &Map.get(&1, user_id))
  def get_state(user_id), do: get_state(user_id |> String.to_integer())

  def set_state(user_id, struct) when is_integer(user_id), do: Agent.update(__MODULE__, &Map.put(&1, user_id, struct))
  def set_state(user_id, struct), do: set_state(user_id |> String.to_integer(), struct)


  def delete_state(user_id) do
    Agent.update(__MODULE__, &Map.drop(&1, [user_id]))
  end
end
