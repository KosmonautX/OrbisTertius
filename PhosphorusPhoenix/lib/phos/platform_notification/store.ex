defmodule Phos.PlatformNotification.Store do
  use GenServer

  @moduledoc """
  Store module is extensible from default notification type

  Struct for this module is:
    - action_path: can be string or nil value. this value used to navigate to application
    - active: boolean value to identify this notification active or not. default false
    - actor: this can be map or struct, can be either ORB, USR, Memories, etc
    - id: ID used to retry the notification
    - template_id: Linked to Template module
    - retry_after: If notification cannot sent, should retry after x minutes. default: 1
    - retry_attempt: Tries to sent notification, default: 0
    - notify_type: notification type, 1 for them self, 2 for around them


  """

  @type t :: %__MODULE__{
    active: boolean(),
    actor: map() | struct(),
    id: non_neg_integer(),
    notify_type: non_neg_integer(),
    retry_after: non_neg_integer(),
    retry_attempt: non_neg_integer(),
    template_id: String.t(),
  }
  @enforce_keys [:actor, :id, :template_id]

  defstruct [:actor, :id, :template_id, retry_after: 5, retry_attempt: 0, active: false, notify_type: 1]

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do 
    table = :ets.new(:platform_notification_store, [:set, :protected, read_concurrency: true])
    {:ok, table}
  end

  @doc """
  list function used to list all notification store
  
    Example:
      iex> list()
      [%Phos.PlatformNotification.Store{}, ...]
  
  """
  @spec list :: [t()]
  def list do
    GenServer.call(__MODULE__, :list)
  end

  @doc """
  get function used to get detail notification
  
    Example:
      iex> get(1)
      %Phos.PlatformNotification.Store{
        id: 1,
        ...
      }
  
  """
  @spec get(id :: non_neg_integer()) :: t()
  def get(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  @doc """
  update function used to update notification to store. Update fields just retry_attempt
  
    Example:
      iex> update(1, %{retry_attempt: 1})
      %Phos.PlatformNotification.Store{
        id: 1,
        retry_attempt: 2,
        ...
      }
  """
  @spec update(id :: non_neg_integer(), updated_data :: map() | t()) :: :ok | :error
  def update(id, updated_data) do
    GenServer.call(__MODULE__, {:update, id, updated_data})
  end

  @doc """
  backup function used to backup entire data to s3

    Example:
      iex> backup()
      :ok
  
  """
  @spec backup(prefix :: String.t()) :: :ok | :error
  def backup(prefix \\ "") do
    GenServer.cast(__MODULE__, {:backup, db_name(prefix)})
  end

  @doc """
  reload function used to reload current or specific notification time

    Example:
      iex> reload()
      :ok

      iex> reload("2023-03-28")
      :ok
  
  """
  @spec reload(name :: String.t()) :: :ok | :error
  def reload(name \\ "") do
    GenServer.cast(__MODULE__, {:reload, db_name(name)})
  end

  @doc """
  delete function used to delete entire backup

    Example:
      iex> delete()
      :ok

      iex> delete("2023-03-28")
      :ok

      iex> delete("not present")
      :error
  
  """
  @spec delete(name :: String.t()) :: :ok | :error
  def delete(name \\ "") do
    GenServer.cast(__MODULE__, {:delete, db_name(name)})
  end


  @doc """
  reload function used to reload current or specific notification time

    Example:
      iex> insert(%{id: 1, ..})
      %Phos.PlatformNotification.Store{
        id: 1,
        retry_attempt: 2,
        ...
      }
  
  """
  @spec insert(data :: t()) :: {:ok, t()} | {:error, reason :: String.t()}
  def insert(data) do
    GenServer.call(__MODULE__, {:insert, data})
  end

  @impl true
  def handle_call({:get, id}, _from, state) do
    case lookup(state, id) do
      {:ok, data, active} -> {:reply, Map.put(data, :active, active), state}
      _ -> {:reply, "data not found", state}
    end
  end

  @impl true
  def handle_call({:update, id, data}, _from, state) do
    case lookup(state, id) do
      {:ok, _data, current_status} when current_status == data -> {:reply, "Cannot update status", state}
      _ -> {:reply, "data not found", state}
    end
  end

  @impl true
  def handle_call({:delete, id}, _from, state) do
    #TODO: to be implemented wheter using s3 or postgres
    {:ok, data, _} = lookup(state, id)
    {:reply, data, state}
  end

  @impl true
  def handle_call(:list, _from, state) do
    data = 
      :ets.tab2list(state)
      |> Enum.map(fn {_id, d, active} ->
        Map.put(d, :active, active)
      end)

    {:reply, data, state}
  end

  @impl true
  def handle_call({:insert, data}, _from, state) do
    insert_data(state, data)
    {:reply, struct(__MODULE__, data), data}
  end

  @impl true
  def handle_cast({:reload, name}, state) do
    # TODO: reload from backup table
    {:noreply, state}
  end

  @impl true
  def handle_cast({:backup, name}, state) do
    # TODO: backup to persistent datastore
    {:noreply, state}
  end

  defp lookup(table, id) do
    case :ets.lookup(table, id) do
      [{_id, data, active}] -> {:ok, data, active}
      _ -> {:error, "data not found", false}
    end
  end

  defp insert_data(table, data) do
    notification = struct(__MODULE__, data)
    :ets.insert_new(table, {notification.id, notification})
  end

  defp db_name(""), do: Timex.format!(DateTime.utc_now(), "{YYYY}-{M}-{D}")
  defp db_name(name), do: name
end
