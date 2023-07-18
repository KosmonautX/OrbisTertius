defmodule Phos.TeleBot.StateManager do
  defstruct [:telegram_id, state: "start", path: "", data: %{return_to: ""}, metadata: %{message_id: "", last_active: DateTime.utc_now() |> DateTime.to_unix()}]
  use Agent

  use Fsmx.Struct, transitions: %{
    "start" => :*,
    :* => "start"
  }

  @expiry_timeout_in_sec 600

  def start_link(_initial_value) do
    :ok = Phos.TeleBot.Config.load()
    {:ok, pid} = Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def new_state(user_id) when is_integer(user_id) do
    Agent.update(__MODULE__, &Map.put(&1, user_id, %Phos.TeleBot.StateManager{}))
  end
  def new_state(user_id), do: new_state(user_id |> String.to_integer())

  def get_state(user_id) when is_integer(user_id) do
    case Agent.get(__MODULE__, &Map.get(&1, user_id)) do
      nil -> {:error, nil}
      state -> {:ok, state}
    end
  end
  def get_state(user_id), do: get_state(user_id |> String.to_integer())

  def set_state(user_id, struct) when is_integer(user_id) do
    check_state_expiry(user_id)
    Agent.update(__MODULE__, &Map.put(&1, user_id, struct))
  end
  def set_state(user_id, struct), do: set_state(user_id |> String.to_integer(), struct)

  def delete_state(user_id) do
    Agent.update(__MODULE__, &Map.drop(&1, [user_id]))
  end

  def check_state_expiry(user_id) do
    with {:ok, %{metadata: %{last_active: unix_time}} = user_state} <- get_state(user_id) do
      if (DateTime.utc_now() |> DateTime.to_unix()) - unix_time > @expiry_timeout_in_sec do
        delete_state(user_id)
      else
        Agent.update(__MODULE__, &Map.put(&1, user_id, %{metadata: %{last_active: DateTime.utc_now() |> DateTime.to_unix()}}))
        Process.send_after(self(), :delete_expiry_states, @expiry_timeout_in_sec * 1000)
      end
    else
      err -> raise err
    end
  end

  def handle_info(:delete_expiry_states, state) do
    check_state_expiry(state)
    {:noreply, state}
  end
end
