defmodule Phos.Notification.Counter do
  use Agent

  def start_link(opts \\ []) do
    val = Keyword.get(opts, :initial_value, 0)
    Agent.start_link(fn -> val end, name: __MODULE__)
  end

  def current do
    Agent.get_and_update(__MODULE__, fn state ->
      max_poll = DynamicSupervisor.count_children(Phos.Notification.Poller) |> Map.get(:active, 5)
      next_state = rem(state + 1, max_poll)
      {state, next_state}
    end)
  end
end
