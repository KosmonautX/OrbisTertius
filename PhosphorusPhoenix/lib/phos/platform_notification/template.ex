defmodule Phos.PlatformNotification.Template do
  use GenServer

  @moduledoc """
  Template module used to store template of notification

  Template might be stored in single ets file and can be backed up to s3 or can be save to external database (like: notion, ecto or etc)
  
  Template must be have unique identifier to identify their function or behavior, specified field of the Template listed below:
    - id: Unique identifier, must be string and always downcase.
    - body: Body of the notification, long text with parsed content
    - subtitle: Subtitle of the notification, can be blank
    - receiver_name: Receiver name of the notification. this item should be parsed and can change dynamically
    - sender_name: Sender name of the notification. this item should be parsed and can change dynamically
    - event_name: Event name of the notification. this item should be parsed and can change dynamically
  """

  @type t() :: %__MODULE__{
    id: String.t(),
    body: String.t(),
    title: String.t(),
    subtitle: String.t(),
    receiver_name: boolean(),
    sender_name: boolean(),
    event_name: boolean(),
    counter: integer(),
  }
  @type parsed() :: %{
    title: String.t(),
    subtitle: String.t(),
    body: String.t()
  }
  @enforce_keys [:id, :body, :title]
  @default_backup :s3

  defstruct [:id, :body, :title, :subtitle, receiver_name: false, sender_name: false, event_name: false, counter: false]

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  
  @impl true
  def init(_opts) do
    table = :ets.new(:platform_notification_template, [:set, :protected, read_concurrency: true])
    {:ok, table}
  end

  @doc """
  Function for adding item to database

      Example:
      iex> data = %{id: Ecto.UUID.generate(), body: "Lorem Ipsum", title: "Sample title"}
      %{id: Ecto.UUID.generate(), body: "Lorem Ipsum", title: "Sample title"}

      iex> add(data)
      :ok
  """
  @spec add(item :: map()) :: {:ok, t()} | {:error, reason :: String.t()}
  def add(item) do
    GenServer.call(__MODULE__, {:add, item})
  end

  @doc """
  Function to list all template in database

      Example:
      iex> list()
      []

      iex> list()
      [%__MODULE__{id: "uuid", ...}]
  """
  @spec list :: [t()] | []
  def list do
    GenServer.call(__MODULE__, :list)
  end

  @doc """
  Function to reload existing database. Can be from s3, notion, etc.

      Example:
      iex> reload()
      :ok
  """
  @spec reload :: :ok
  def reload do
    GenServer.cast(__MODULE__, {:reload_from, @default_backup})
  end

  @doc """
  Function to reload database with specific name

      Example:
      iex> reload_from("s3")
      :ok
  """
  @spec reload_from(text :: String.t()) :: :ok
  def reload_from(text) do
    GenServer.cast(__MODULE__, {:reload_from, text})
  end

  @doc """
  Function to remove item from database

      Example:
      iex> remove("email_verification")
      {:ok, %{id: "email_verification", ...}}

      iex> remove("not_exists")
      {:error, "Your data moved or already deleted"}

  """
  @spec remove(id :: String.t()) :: {:ok, t()} | {:error, reason :: String.t()}
  def remove(id) do
    GenServer.call(__MODULE__, {:remove, id})
  end

  @doc """
  Function to back up to s3 bucket or persistent database

      Example:
      iex> backup
      :ok
  """
  @spec backup() :: :ok
  def backup do
    GenServer.cast(__MODULE__, {:backup_to, @default_backup})
  end

  @doc """
  Function to back up to s3 bucket or persistent database

      Example:
      iex> backup_to("s3")
      :ok
  """
  @spec backup_to(destination :: String.t()) :: :ok
  def backup_to(destination) do
    GenServer.cast(__MODULE__, {:backup_to, destination})
  end

  @doc """
  Function to get data from database. Returns {:ok, data} or {:error, reason}

      Example:
      iex> get("email_verification")
      {:ok, %__MODULE__{
        id: "email_verification",
        ...
      }}

      iex> get("not_exists")
      {:error, "Your data is moved or already deleted"}
  """
  @spec get(id :: String.t()) :: {:ok, t()} | {:error, reason :: String.t()}
  def get(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  @doc """
  Function to get and also parsed data to string. Returns {:ok, parsed_data} or {:error, reason}

      Example:
      iex> parse("email_verification")
      {:ok, %{
        title: "Hey Jane, you have 3 friend request",
        ...
      }}

      iex> get("not_exists")
      {:error, "Your data is moved or already deleted"}
  """
  @spec parse(id :: String.t(), opts :: list()) :: {:ok, result :: parsed()} | {:error, reason :: String.t()}
  def parse(id, opts \\ []) do
    GenServer.call(__MODULE__, {:parse, id, opts})
  end

  @impl true
  def handle_call({:add, item}, _from, state) do
    data = struct(__MODULE__, item)
    insert(state, data)
    {:reply, data, state}
  end

  @impl true
  def handle_call(:list, _from, state) do
    data = :ets.tab2list(state)
    {:reply, data, state}
  end

  @impl true
  def handle_call({:remove, id}, _from, state) do
    case lookup(state, id) do
      {:ok, data} -> 
        :ets.delete(state, id)
        {:reply, data, state}
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end

  @impl true
  def handle_call({:get, id}, _from, state) do
    {:reply, lookup(state, id), state}
  end

  @impl true
  def handle_call({:parse, id, option}, _from, state) do
    case lookup(state, id) do
      {:ok, data} -> {:reply, parse_data(data, option), state}
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end

  defp insert(table, %__MODULE__{id: id} = data) do
    case lookup(table, id) do
      {:ok, _data} -> {:error, "Duplicate id detected"}
      _ -> :ets.insert(table, {id, data})
    end
  end

  defp lookup(table, id) do
    case :ets.lookup(table, id) do
      [{_id, data}] -> {:ok, data}
      _ -> {:error, "Your data is moved or already deleted"}
    end
  end

  defp parse_data(data, options) do
    keys =
      data
      |> Map.from_struct()
      |> Enum.reduce([], fn {k, v}, acc ->
        case v do
          true -> [k | acc]
          _ -> acc
        end
      end)

    %{
      body: replace_data_value(data.body, keys, options),
      title: replace_data_value(data.title, keys, options),
      subtitle: replace_data_value(data.subtitle, keys, options),
    }
  end

  defp replace_data_value(data, _keys, _options) when data in ["", nil], do: ""
  defp replace_data_value(data, keys, options) do
    Enum.reduce(keys, data, fn v, acc ->
      String.replace(acc, "{#{v}}", Keyword.get(options, v, ""))
    end)
  end
end
