defmodule Phos.Notification.Subscriber do
  require Logger

  use GenServer, restart: :permanent

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_opts) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:subscribe, tokens, topic}, state) do
    case Fcmex.Subscription.subscribe(topic, tokens) do
      {:ok, _result} -> {:noreply, state}
      {:error, err} ->
        Logger.error(err)
        {:noreply, state, {:continue, err}}
    end
  end

  @impl true
  def handle_cast({:unsubscribe, tokens, topic}, state) do
    Fcmex.Subscription.unsubscribe(topic, tokens)
    {:noreply, state}
  end

  @impl true
  def handle_call({:target, condition, notification, data}, _from,  state) do
    result = Fcmex.push("", notification: notification, condition: condition, data: data)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:push, tokens, notification}, _from, state) do
    result =
      Fcmex.push(tokens, notification: notification)
      |> Enum.reduce(%{succeeded: 0, failed: 0}, fn x, %{succeeded: suc, failed: fail} = acc ->
        case elem(x, 0) do
          :ok ->
            res = elem(x, 1)
            %{acc | succeeded: suc + Map.get(res, "success", 1), failed: fail + Map.get(res, "failure", 1)}
          _ -> %{acc | failed: fail + Map.get(elem(x, 1), "failure", 1)}
        end
      end)

    {:reply, result, state}
  end

  @impl true
  def handle_call({:push, tokens, notification, data}, _from, state) do
    result =
      Fcmex.push(tokens, notification: notification, data: data)
      |> Enum.reduce(%{succeeded: 0, failed: 0}, fn x, %{succeeded: suc, failed: fail} = acc ->
        case elem(x, 0) do
          :ok -> %{acc | succeeded: suc + Map.get(x, "success", 1)}
          _ -> %{acc | failed: fail + Map.get(x, "failure", 1)}
        end
      end)

    {:reply, result, state}
  end
end

defimpl Jason.Encoder, for: Fcmex.Payload do
  # Notification Parameters to Legacy FCM API
  def encode(value, opts) do
    Map.take(value, [:to, :condition, :notification, :registration_ids, :data])
    |> Jason.Encode.map(opts)
  end
end
