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
    success: boolean(),
    spec: Phos.PlatformNotification.t(),
    id: non_neg_integer(),
    retry_after: non_neg_integer(),
    retry_attempt: non_neg_integer(),
    next_execute_at: DateTime.t(),
    error_reason: String.t(),
  }

  defstruct [:id, :spec, :error_reason, :next_execute_at, retry_after: 5, retry_attempt: 0, active: false, success: false]

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

  def schedulled do
    filter = [{
      { :_, :_, :"$1", :"$2"},
      [{:==, :"$1", true}],
      [:"$_"]
    }]

    filter(filter)
  end

  def filter(filter) do
    GenServer.call(__MODULE__, {:filter, filter})
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
      {:ok, data} -> {:reply, data, state}
      _ -> {:reply, "data not found", state}
    end
  end

  @impl true
  def handle_call({:update, id, data}, _from, state) do
    case lookup(state, id) do
      {:ok, existing} ->
        updated = Map.merge(existing, data)
        :ets.delete(state, id)
        insert_data(state, updated)
        {:reply, updated, state}
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
      |> Enum.map(fn {_id, d, _active, _success} ->
        d
      end)

    {:reply, data, state}
  end

  @impl true
  def handle_call({:insert, params}, _from, state) do
    data = struct(__MODULE__, params)
    
    insert_data(state, data)
    {:reply, data, state}
  end

  @impl true
  def handle_call({:filter, filter}, _from, state) do
    case filter_by(state, filter) do
      {:ok, data} -> {:reply, data, state}
      _ -> {:reply, nil, state}
    end
  end

  @impl true
  def handle_cast({:reload, _name}, state) do
    # TODO: reload from backup table
    {:noreply, state}
  end

  @impl true
  def handle_cast({:backup, _name}, state) do
    # TODO: backup to persistent datastore
    {:noreply, state}
  end

  defp lookup(table, id) do
    case :ets.lookup(table, id) do
      [{_id, data, _active, _success}] -> {:ok, data}
      _ -> {:error, "data not found"}
    end
  end

  defp insert_data(table, %__MODULE__{id: id, active: active, success: success} = data) do
    case lookup(table, id) do
      {:ok, _existing, _, _} -> {:error, "Duplicate ID record"}
        _ -> :ets.insert(table, {id, data, active, success})
    end
  end

  defp filter_by(table, filter) do
    IO.inspect(filter)
    :ets.select(table, filter)
  end

  defp db_name(""), do: Timex.format!(DateTime.utc_now(), "{YYYY}-{M}-{D}")
  defp db_name(name), do: name
end
