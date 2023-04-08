defmodule Phos.PlatformNotification.Producer do
  use GenStage

  @moduledoc """
  Phos.PlatformNotification.Producer is used to create notification.
  Notification is based on {:type, :entity, :id, :msg_id} tuple

  :type considered as :email, or :push
  :entity considered as "ORB", "USR", "COMMENT"
  :id considered as identifier for :entity
  :template_id template id listed in database

  Example:

      iex> notify({:email, "USR", "uuid", 1})
           :ok

      iex> notify({:push, "ORB", "uuid", 2})
           :ok
  """

  alias Phos.PlatformNotification, as: PN

  def start_link(number) do
    GenStage.start_link(__MODULE__, number, name: __MODULE__)
  end

  @impl true
  def init(_counter) do
    {:producer, 1, dispatcher: {GenStage.DemandDispatcher, max_demand: max_demand()}}
  end

  defp max_demand(), do: Keyword.get(config(), :max_demand, 1000)

  defp config do
    PN.config()
    |> Keyword.take([:max_demand, :min_demand])
  end

  @doc """
  Notify is used to create notifier to consumer and filtered in dispatcher
  """
  @spec notify(event :: PN.t(), options :: Keyword.t(), timeout :: non_neg_integer()) :: :ok
  def notify(event, options, timeout \\ 5000) do
    GenStage.call(__MODULE__, {:notify, event, options}, timeout)
  end

  @impl true
  def handle_demand(demand, state) when state > 1 do
    events = Enum.to_list(state..state+demand-1)
    {:noreply, events, demand - (state - 1)}
  end

  @impl true
  def handle_demand(_demand, state) do
    {:noreply, [], state}
  end

  @impl true
  def handle_call({:notify, {type, entity, id, template_id}, options}, _from, state) do
    event = %{
      "type" => to_string(type),
      "entity" => entity,
      "entity_id" => id,
      "template_id" => template_id,
      "options" => Enum.into(options, %{})
    }
    {:reply, :ok, [event], state + 1}
  end

  @impl true
  def handle_call({:notify, notification_id, options}, _from, state) do
    {:reply, :ok, [%{"notification_id" => notification_id, "options" => options}], state + 1}
  end

  @impl true
  def handle_info({_from, :ok}, state) do
    {:noreply, [], state - 1}
  end

  @impl true
  def handle_info({_from, :error}, state) do
    {:noreply, [], state} end
end
