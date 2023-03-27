defmodule Phos.PlatformNotification do
  use Supervisor

  @type notification_type :: :email | :push
  @type entity :: String.t()
  @type entity_id :: String.t() | integer()
  @type message_type :: integer()

  alias __MODULE__.{Producer, Dispatcher, Consumer, Store}

  @moduledoc """
  PlatformNotification used to generate notification with flexibility
  Notification can be triggered using manual notify, or scheduller

  The schema is

  [Scheduller] <-> [Store]
       |             |
  [Producer] -> [Dispatcher] <-> [Consumer]

  The executor should be the customer,
  Dispatcher module to filter and get some data and pass to the Customer
  If The customer failed to execute the events, It return to the dispatcher and should be retry in desired seconds

  Scheduller used to check every minute, and if there is any notification should execute, the module will execute based on the specification
  Store is the notification message store. Can be composed, JSON based and linked to the persistent database. To track the history and etc.

  Consumer can be more than one worker(s) specified in the config file
  Algorithm for distribution just like simple queue, and make sure that all the customer have same amount of work
  Only consumer can trigger the notification (email, broadcast, or push)
  If consumer failed the execution, should tell the dispatcher the event is failed, and Dispatcher should reschedule after certain amount of time
  """

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    number    = Keyword.get(config(), :worker, 4)
    workers   = Enum.map(1..number, fn n -> Supervisor.child_spec({Consumer, []}, id: :"platfrom_notification_worker_#{n}") end)
    children  = [Producer, Dispatcher, Store | workers]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def config() do
    Application.get_env(:phos, __MODULE__, [])
  end

  @spec notify({notification_type, entity, entity_id, message_type}) :: :ok | :error
  def notify({_name, _entity, _entity_id, _msg_type} = data), do: Producer.notify(data)
  def notify(_data), do: :error
end
