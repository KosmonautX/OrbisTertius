defmodule Phos.Message do
  @moduledoc """
  The Message context.
  """

  import Ecto.Query, warn: false
  alias Phos.Repo

  alias Phos.Message.Echo

  @doc """
  Returns the list of echoes.

  ## Examples

      iex> list_echoes()
      [%Echo{}, ...]

  """
  def list_echoes do
    Repo.all(Echo)
  end


  @doc """
  Returns paginated call of the last message between each unique source destination pair

  ## Examples

      iex> last_echoes()
      [%Echo{}, ...]

  """

  def last_echoes(id, page, sort_attribute \\ :inserted_at, limit \\ 12) do
    archetype = "USR"
    #dbg()
    Phos.Message.Echo
    |> where([e], e.source == ^id and e.source_archetype == ^archetype )
    |> or_where([e], e.destination == ^id and e.destination_archetype == ^archetype)
    |> distinct([e], [e.source, e.destination])
    |> order_by([e], desc: e.inserted_at)
    |> Repo.Paginated.all(page, sort_attribute, limit)
  end

  @doc """
  Returns paginated call of the messages between for one unique source destination pair

  ## Examples

      iex> list_echoes()
      [%Echo{}, ...]

  """

  def list_echoes_by_pair({id, yours}, page, sort_attribute \\ :inserted_at, limit \\ 12) do
    archetype = "USR"
    Phos.Message.Echo
    |> where([e], (e.source == ^id and e.source_archetype == ^archetype) and (e.destination == ^yours and e.destination_archetype == ^archetype))
    |> or_where([e], (e.source == ^yours and e.source_archetype == ^archetype) and (e.destination == ^id and e.destination_archetype == ^archetype))
    |> distinct([e], e.subject)
    |> order_by([e], desc: e.inserted_at)
    |> Repo.Paginated.all(page, sort_attribute, limit)
  end

  @doc """

  Query Builder for Symmetric Source & Destination

  ## Examples

      iex> list_echoes()
      [%Echo{}, ...]

  """

    def ur_call(archetype, id) do
    query = Phos.Message.Echo
    |> where([e], e.source == ^id and e.source_archetype == ^archetype )
    |> or_where([e], e.destination == ^id and e.destination_archetype == ^archetype)
    |> order_by([e], desc: e.inserted_at)
    Phos.Repo.all(query, limit: 8)
  end

  def usr_call(id) do
    ur_call("USR", id) #user-user specific call
  end


  @doc """
  Gets a single echo.

  Raises `Ecto.NoResultsError` if the Echo does not exist.

  ## Examples

      iex> get_echo!(123)
      %Echo{}

      iex> get_echo!(456)
      ** (Ecto.NoResultsError)

  """
  def get_echo!(id), do: Repo.get!(Echo, id)

  @doc """
  Creates a echo.

  ## Examples

      iex> create_echo(%{field: value})
      {:ok, %Echo{}}

      iex> create_echo(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_echo(attrs \\ %{}) do
    %Echo{}
    |> Echo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a echo.

  ## Examples

      iex> update_echo(echo, %{field: new_value})
      {:ok, %Echo{}}

      iex> update_echo(echo, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_echo(%Echo{} = echo, attrs) do
    echo
    |> Echo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a echo.

  ## Examples

      iex> delete_echo(echo)
      {:ok, %Echo{}}

      iex> delete_echo(echo)
      {:error, %Ecto.Changeset{}}

  """
  def delete_echo(%Echo{} = echo) do
    Repo.delete(echo)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking echo changes.

  ## Examples

      iex> change_echo(echo)
      %Ecto.Changeset{data: %Echo{}}

  """

  def change_echo(%Echo{} = echo, attrs \\ %{}) do
    Echo.changeset(echo, attrs)
  end


  alias Phos.Message.Memory

  @doc """
  Returns the list of memories.

  ## Examples

      iex> list_memories()
      [%Memory{}, ...]

  """
  def list_memories do
    Repo.all(Memory)
  end

  @doc """
  Gets a single memory.

  Raises `Ecto.NoResultsError` if the Memory does not exist.

  ## Examples

      iex> get_memory!(123)
      %Memory{}

      iex> get_memory!(456)
      ** (Ecto.NoResultsError)

  """
  def get_memory!(id), do: Repo.get!(Memory, id)


    @doc """
  Create a Message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Memory{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

    def create_message(%{"id" => mem_id, "user_source_id" => i_id, "rel_subject_id" => rel_id, "user_destination_id"=> a_id} = params) do
      attrs = params
      |> Map.put("reveries", [%{"user_destination_id" => i_id, "memory_id" => mem_id},
                             %{"user_destination_id" => a_id, "memory_id" => mem_id}])
      {:ok, gen_memory(attrs)}
    end

  @doc """
  Creates a memory.

  ## Examples

      iex> create_memory(%{field: value})
      {:ok, %Memory{}}

      iex> create_memory(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_memory(%{"id" => _id} = attrs) do
    %Memory{}
    |> Memory.changeset(attrs)
    |> Repo.insert()
  end

  def create_memory(attrs \\ %{}) do
    %Memory{}
    |> Memory.changeset(attrs |> Map.put(:id, Ecto.UUID.generate()))
    |> Repo.insert()
  end

  def gen_memory(attrs \\ %{}) do
    %Memory{}
    |> Memory.gen_reveries_changeset(attrs)
    |> Repo.insert!()
    |> Repo.preload([:orb_subject, :rel_subject])
  end

  @doc """
  Updates a memory.

  ## Examples

      iex> update_memory(memory, %{field: new_value})
      {:ok, %Memory{}}

      iex> update_memory(memory, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_memory(%Memory{} = memory, attrs) do
    memory
    |> Memory.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a memory.

  ## Examples

      iex> delete_memory(memory)
      {:ok, %Memory{}}

      iex> delete_memory(memory)
      {:error, %Ecto.Changeset{}}

  """
  def delete_memory(%Memory{} = memory) do
    Repo.delete(memory)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking memory changes.

  ## Examples

      iex> change_memory(memory)
      %Ecto.Changeset{data: %Memory{}}

  """
  def change_memory(%Memory{} = memory, attrs \\ %{}) do
    Memory.changeset(memory, attrs)
  end

  alias Phos.Message.Reverie

  @doc """
  Returns the list of reveries.

  ## Examples

      iex> list_reveries()
      [%Reverie{}, ...]

  """
  def list_reveries do
    Repo.all(Reverie)
  end

  @doc """
  Gets a single reverie.

  Raises `Ecto.NoResultsError` if the Reverie does not exist.

  ## Examples

      iex> get_reverie!(123)
      %Reverie{}

      iex> get_reverie!(456)
      ** (Ecto.NoResultsError)

  """
  def get_reverie!(id), do: Repo.get!(Reverie, id)

  @doc """
  Creates a reverie.

  ## Examples

      iex> create_reverie(%{field: value})
      {:ok, %Reverie{}}

      iex> create_reverie(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_reverie(attrs \\ %{}) do
    %Reverie{}
    |> Reverie.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a reverie.

  ## Examples

      iex> update_reverie(reverie, %{field: new_value})
      {:ok, %Reverie{}}

      iex> update_reverie(reverie, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_reverie(%Reverie{} = reverie, attrs) do
    reverie
    |> Reverie.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a reverie.

  ## Examples

      iex> delete_reverie(reverie)
      {:ok, %Reverie{}}

      iex> delete_reverie(reverie)
      {:error, %Ecto.Changeset{}}

  """
  def delete_reverie(%Reverie{} = reverie) do
    Repo.delete(reverie)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking reverie changes.

  ## Examples

      iex> change_reverie(reverie)
      %Ecto.Changeset{data: %Reverie{}}

  """
  def change_reverie(%Reverie{} = reverie, attrs \\ %{}) do
    Reverie.changeset(reverie, attrs)
  end
end
