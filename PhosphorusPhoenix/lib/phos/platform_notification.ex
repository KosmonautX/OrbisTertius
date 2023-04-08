defmodule Phos.PlatformNotification do
  use Supervisor

  @type notification_type :: :email | :push
  @type entity :: String.t()
  @type entity_id :: String.t() | integer()
  @type message_type :: integer()

  @type t :: {notification_type(), entity(), entity_id(), message_type()}

  alias __MODULE__.{Producer, Dispatcher, Consumer, Store, Scheduller, Template, Listener}

  import Ecto.Query, warn: false

  alias Phos.Repo

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
    children  = [Producer, Dispatcher, Listener, Scheduller | workers]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def config() do
    Application.get_env(:phos, __MODULE__, [])
  end

  @spec notify(t(), option :: Keyword.t()) :: :ok | :error
  def notify(data, options \\ []), do: Producer.notify(data, options)

  def create_template(attrs) do
    opts = Map.put_new(attrs, :id, Ecto.UUID.generate())

    %Template{}
    |> Template.changeset(opts)
    |> Repo.insert()
  end

  def get_template(id) do
    query = from t in Template, where: t.id == ^id, limit: 1
    Repo.one(query)
  end

  def get_template_by_key(key) do
    query = from t in Template, where: t.key == ^key, limit: 1
    Repo.one(query)
  end

  def update_template(template, attrs) do
    template
    |> Template.changeset(attrs)
    |> Repo.update()
  end

  def insert_notification(attrs) do
    opts = Map.put_new(attrs, :id, Ecto.UUID.generate())

    %Store{}
    |> Store.changeset(opts)
    |> Repo.insert()
  end

  def update_notification(store, attrs) do
    store
    |> Store.changeset(attrs)
    |> Repo.update()
  end

  def get_notification(id) do
    query = from s in Store, where: s.id == ^id, preload: [:template], limit: 1
    Repo.one(query)
  end

  def active_notification() do
    time = DateTime.utc_now()
    query = from s in Store, where: s.active == true and s.retry_attempt <= 5 and s.next_execute_at <= ^time
    query = where(query, [s], is_nil(s.success) or s.success == false)

    Repo.all(query)
  end
end
