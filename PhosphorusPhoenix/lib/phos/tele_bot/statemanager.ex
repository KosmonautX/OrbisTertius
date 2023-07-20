defmodule Phos.TeleBot.StateManager do
  defstruct [:telegram_id,
    branch: %{}]

  alias TeleBot.Cache

  @ttl 600_000

  def new_state(user_id) when is_integer(user_id) do
    Cache.put(user_id, %__MODULE__{telegram_id: user_id}, ttl: @ttl)
    {:ok, %__MODULE__{telegram_id: user_id}}
  end
  def new_state(user_id), do: new_state(user_id |> String.to_integer())

  def get_state(user_id) when is_integer(user_id) do
    case Cache.get(user_id) do
      nil -> {:error, nil}
      state -> {:ok, state}
    end
  end
  def get_state(user_id), do: get_state(user_id |> String.to_integer())

  def set_state(user_id, struct) when is_integer(user_id) do
    with {:ok, _} <- get_state(user_id) do
      {prev, updated_struct} =
        Cache.get_and_update(user_id, fn curr_struct ->
          {curr_struct, struct}
        end, ttl: @ttl)
        {:ok, updated_struct}
      else
        {:error, nil} -> {:error, nil}
    end
  end
  def set_state(user_id, struct), do: set_state(user_id |> String.to_integer(), struct)

  def update_state(struct, user_id) when is_integer(user_id) do
    set_state(user_id, struct)
  end
  def update_state(struct, user_id), do: update_state(struct, user_id |> String.to_integer())

  def delete_state(user_id) do
    Cache.delete(user_id)
  end
end
