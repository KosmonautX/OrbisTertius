defmodule Phos.TeleBot.Remainder do
  use Agent

  def start_link(_initial_value) do
    :ok = Phos.TeleBot.Config.load()
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def set_location(user_id, location_type) do
    Agent.update(__MODULE__, &Map.put(&1, user_id, location_type))
  end

  def get_location(user_id) do
    Agent.get(__MODULE__, &Map.get(&1, user_id))
  end

  def remove_location(user_id) do
    Agent.update(__MODULE__, &Map.drop(&1, [user_id]))
  end
end
