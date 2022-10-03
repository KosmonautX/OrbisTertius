defmodule Phos.Notification.Subcriber do
  require Logger

  use GenServer, restart: :permanent

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: {:global, __MODULE__})
  end

  @impl true
  def init(_opts) do
    {:ok, []}
  end

  def subscribe(token, topic) when is_bitstring(token), do: subscribe([token], topic)
  def subscribe(tokens, topic) do
    GenServer.cast({:global, __MODULE__}, {:subscribe, tokens, topic})
  end

  def unsubscribe(token, topic) when is_bitstring(token), do: unsubscribe([token], topic)
  def unsubscribe(tokens, topic) when is_list(tokens) do
    GenServer.cast({:global, __MODULE__}, {:unsubcribe, tokens, topic})
  end

  def push(token, notification) when is_bitstring(token), do: push([token], notification)
  def push(tokens, notification) when is_list(tokens) do
    GenServer.call({:global, __MODULE__}, {:push, tokens, notification})
  end

  def push(token, notification, data) when is_bitstring(token), do: push([token], notification, data)
  def push(tokens, notification, data) when is_list(tokens) do
    GenServer.call({:global, __MODULE__}, {:push, tokens, notification, data})
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
  def handle_cast({:unsubcribe, tokens, topic}, state) do
    Fcmex.Subscription.unsubscribe(topic, tokens)
    {:noreply, state}
  end

  @impl true
  def handle_call({:push, tokens, notification}, _from, state) do
    case Fcmex.push(tokens, notification: notification) do
      [ok: body] -> {:reply, body, state}
      [err: err] -> {:reply, {:error, err}, state}
    end
  end

  @impl true
  def handle_call({:push, tokens, notification, data}, _from, state) do
    case Fcmex.push(tokens, notification: notification, data: data) do
      [ok: body] -> {:reply, body, state}
      [err: err] -> {:reply, {:error, err}, state}
    end
  end
end
