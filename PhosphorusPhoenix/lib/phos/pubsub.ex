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

  def publish({:ok, message}, event, topics) when is_list(topics) do
    topics
    |> Enum.map(fn topic -> publish(message, event, topic) end)
    {:ok, message}
  end

  def publish({:ok, message}, event, topic) do
    PubSub.broadcast(Phos.PubSub, topic, {__MODULE__, event, message})
    {:ok, message}
  end

  def publish(message, event, topics) when is_list(topics) do
    topics |> Enum.map(fn topic -> publish(message, event, topic) end)
    message
  end

  def publish(%Phos.Message.Memory{user_source: user} = message, event, %Phos.Users.RelationBranch{user_id: user_id}) do
        PubSub.broadcast(__MODULE__, "memory:user:#{user_id}", {__MODULE__, event, message})
        if(user_id != user.id) do
          Phos.Notification.target("'USR.#{user_id}' in topics",
          %{title: "Message from #{user.username}", body: message.message},
          %{action_path: "/memland/memories/#{message.rel_subject_id}"}
          )
        end
    message
  end

  def publish(message, event, topic) do
    PubSub.broadcast(Phos.PubSub, topic, {__MODULE__, event, message})
    message
  end

  def publish({:error, reason}, _event) do
    {:error, reason}
  end
end
