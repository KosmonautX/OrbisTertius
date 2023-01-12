defmodule Phos.Notification do
  use Supervisor

  alias Phos.Notification.{Poller, Counter, Scheduller}

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      Poller,
      Scheduller,
      {Counter, [initial_value: 0]},
    ]

    Supervisor.init(children , strategy: :one_for_all)
  end
  def subscribe(token, nil) when is_bitstring(token), do: nil
  def subscribe(token, topic) when is_bitstring(token), do: subscribe([token], topic)
  def subscribe(tokens, topic) do
    GenServer.cast(executor(), {:subscribe, tokens, topic})
  end

  def unsubscribe(token, topic) when is_bitstring(token), do: unsubscribe([token], topic)
  def unsubscribe(tokens, topic) when is_list(tokens) do
    GenServer.cast(executor(), {:unsubscribe, tokens, topic})
  end

  def push(token, notification) when is_bitstring(token), do: push([token], notification)
  def push(tokens, notification) when is_list(tokens) do
    GenServer.call(executor(), {:push, tokens, notification})
  end

  def push(token, notification, data) when is_bitstring(token), do: push([token], notification, data)
  def push(tokens, notification, data) when is_list(tokens) do
    GenServer.call(executor(), {:push, tokens, notification, data})
  end

  def target(condition, notification, data \\ %{}) do
    #`'${topic}' in topics && !('${me}' in topics)`, eg. "'ORB.1' in topics && !('USR.1' in topics)"
    GenServer.call(executor(), {:target, condition, notification, data}, 10_000)

  end

  defp executor do
    current = Counter.current()
    DynamicSupervisor.which_children(Phos.Notification.Poller)
    |> Enum.at(current)
    |> elem(1)
  end
end
