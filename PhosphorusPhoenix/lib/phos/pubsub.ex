defmodule Phos.PubSub do
  @moduledoc """
    Publish Subscriber Pattern
  """
  alias Phoenix.PubSub

  def subscribe(topic) do
    PubSub.subscribe(Phos.PubSub, topic)
  end

  def unsubscribe(topic) do
    PubSub.unsubscribe(Phos.PubSub, topic)
  end

  def publish({:ok, message}, event, topic) do
    PubSub.broadcast(Phos.PubSub, topic, {__MODULE__, event, message})
    {:ok, message}
  end

  def publish(message, event, topic) do
    PubSub.broadcast(Phos.PubSub, topic, {__MODULE__, event, message})
    {:ok, message}
  end

  def publish({:error, reason}, _event) do
    {:error, reason}
  end
end
